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
    case quotaExceeded
    case serverError(message: String)
    case httpError(statusCode: Int)
}

extension AIResponderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Set the OPENAI_API_KEY environment variable to enable the AI assistant."
        case .invalidResponse:
            return "The AI response could not be parsed."
        case .quotaExceeded:
            return "You have reached the AI usage quota. Review your OpenAI usage, plan, and billing settings."
        case .serverError(let message):
            return "The AI service returned an error: \(message)"
        case .httpError(let statusCode):
            return "The AI request failed (HTTP status code: \(statusCode))."
        }
    }
}

struct AIResponderOutput: Decodable {
    let userTranslationJa: String
    let replyEn: String
    let replyJa: String
}

actor AIResponder {
    private struct ChatMessage: Encodable {
        let role: String
        let content: String
    }

    private struct ChatRequest: Encodable {
        struct ResponseFormat: Encodable {
            let type: String
        }

        let model: String
        let messages: [ChatMessage]
        let maxTokens: Int
        let temperature: Double
        let responseFormat: ResponseFormat

        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case maxTokens = "max_tokens"
            case temperature
            case responseFormat = "response_format"
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

    func generateGuidance(for transcript: String) async throws -> AIResponderOutput {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AIResponderError.invalidResponse }

        let messages = [
            ChatMessage(
                role: "system",
                content: """
                You are assisting with live conversations. Always respond with strict JSON that matches this schema:
                {"userTranslationJa":"<Japanese translation of the user's English input>","replyEn":"<a helpful, natural English reply the speaker could say next>","replyJa":"<the Japanese translation of replyEn>"}
                - Keep the translations natural and conversational.
                - replyEn must be in English.
                - replyJa must faithfully translate replyEn into Japanese.
                - Do not wrap the JSON in markdown or add any commentary.
                """
            ),
            ChatMessage(role: "user", content: trimmed)
        ]

        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: messages,
            maxTokens: 256,
            temperature: 0.7,
            responseFormat: .init(type: "json_object")
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
                if httpResponse.statusCode == 429 || apiError.error.message.localizedCaseInsensitiveContains("quota") {
                    throw AIResponderError.quotaExceeded
                }
                throw AIResponderError.serverError(message: apiError.error.message)
            }
            if httpResponse.statusCode == 429 {
                throw AIResponderError.quotaExceeded
            }
            throw AIResponderError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        guard let chatResponse = try? decoder.decode(ChatResponse.self, from: data),
              let message = chatResponse.choices.first?.message?.content else {
            throw AIResponderError.invalidResponse
        }

        let cleaned = message.trimmingCharacters(in: .whitespacesAndNewlines)

        if let parsed = try? decodeOutput(from: cleaned) {
            return parsed
        }

        // Attempt to salvage JSON from the response if the assistant returned leading/trailing text.
        if let fallback = extractJSONObject(from: cleaned),
           let parsed = try? decodeOutput(from: fallback) {
            return parsed
        }

        throw AIResponderError.invalidResponse
    }

    private func decodeOutput(from string: String) throws -> AIResponderOutput {
        guard let data = string.data(using: .utf8) else {
            throw AIResponderError.invalidResponse
        }
        return try JSONDecoder().decode(AIResponderOutput.self, from: data)
    }

    private func extractJSONObject(from text: String) -> String? {
        guard let startIndex = text.firstIndex(of: "{"),
              let endIndex = text.lastIndex(of: "}") else {
            return nil
        }
        return String(text[startIndex...endIndex])
    }
}
