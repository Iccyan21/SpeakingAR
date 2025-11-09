//
//  AIResponder.swift
//  SpeakingAR
//
//  Created to provide AI-generated replies based on the live transcript.
//

import Foundation

enum AIResponderError: Error {
    case missingAPIKey
    case invalidResponse
    case serverError(message: String)
    case httpError(statusCode: Int)
}

extension AIResponderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "AI 応答を利用するには OPENAI_API_KEY を環境変数に設定してください。"
        case .invalidResponse:
            return "AI からの応答を解釈できませんでした。"
        case .serverError(let message):
            return "AI サービスからエラーが返されました: \(message)"
        case .httpError(let statusCode):
            return "AI サービスとの通信に失敗しました (ステータスコード: \(statusCode))。"
        }
    }
}

actor AIResponder {
    private struct ChatMessage: Encodable {
        let role: String
        let content: String
    }

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [ChatMessage]
        let maxTokens: Int
        let temperature: Double

        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case maxTokens = "max_tokens"
            case temperature
        }
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let role: String
                let content: String
            }

            let message: Message?
        }

        let choices: [Choice]
    }

    private struct ErrorResponse: Decodable {
        struct APIError: Decodable {
            let message: String
        }

        let error: APIError
    }

    private let endpoint: URL
    private let apiKey: String
    private let urlSession: URLSession

    init(
        apiKey: String? = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
        endpoint: URL = URL(string: "https://api.openai.com/v1/chat/completions")!,
        urlSession: URLSession = .shared
    ) throws {
        guard let key = apiKey, !key.isEmpty else {
            throw AIResponderError.missingAPIKey
        }
        self.apiKey = key
        self.endpoint = endpoint
        self.urlSession = urlSession
    }

    func generateResponse(for transcript: String) async throws -> String {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AIResponderError.invalidResponse }

        let messages = [
            ChatMessage(role: "system", content: "You are a helpful conversation partner. Reply in the same language as the user in a concise and friendly tone."),
            ChatMessage(role: "user", content: trimmed)
        ]

        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: messages,
            maxTokens: 256,
            temperature: 0.7
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIResponderError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            if let apiError = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AIResponderError.serverError(message: apiError.error.message)
            }
            throw AIResponderError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        guard let chatResponse = try? decoder.decode(ChatResponse.self, from: data),
              let message = chatResponse.choices.first?.message?.content else {
            throw AIResponderError.invalidResponse
        }

        return message.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
