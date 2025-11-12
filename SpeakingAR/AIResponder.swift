//
//  AIResponder.swift
//  SpeakingAR
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

struct AIResponseData {
    let japaneseTranslation: String     // 相手の英語の日本語訳
    let englishReply: String            // AIの英語返答
    let englishReplyJapanese: String    // AIの英語返答の日本語訳 ← 追加
    let katakanaReading: String         // 英語返答のカタカナ読み
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
        apiKey: String? = "API_KEY",
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

    func generateResponse(for transcript: String) async throws -> AIResponseData {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AIResponderError.invalidResponse }

        let systemPrompt = """
        You are a helpful English conversation partner for Japanese speakers.

        The user will speak in English. You must respond with a JSON object containing:
        1. "japanese_translation": A Japanese translation of what the user said
        2. "english_reply": Your natural English reply (short and conversational)
        3. "english_reply_japanese": A Japanese translation of your English reply
        4. "katakana_reading": The katakana pronunciation guide for your English reply

        Example format:
        {
          "japanese_translation": "こんにちは、元気ですか？",
          "english_reply": "I'm doing great, thanks! How about you?",
          "english_reply_japanese": "とても元気だよ、ありがとう！君はどう？",
          "katakana_reading": "アイム ドゥーイング グレイト、サンクス！ ハウ アバウト ユー？"
        }

        Rules:
        - Keep your English reply casual and natural
        - Make the Japanese translation natural and conversational
        - Make the katakana reading easy to pronounce for Japanese speakers
        - Only respond with valid JSON, nothing else
        """

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: trimmed)
        ]

        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: messages,
            maxTokens: 512,
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
              let content = chatResponse.choices.first?.message?.content else {
            throw AIResponderError.invalidResponse
        }

        // JSONをパース
        guard let jsonData = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String],
              let japaneseTranslation = json["japanese_translation"],
              let englishReply = json["english_reply"],
              let englishReplyJapanese = json["english_reply_japanese"],
              let katakanaReading = json["katakana_reading"] else {
            throw AIResponderError.invalidResponse
        }

        return AIResponseData(
            japaneseTranslation: japaneseTranslation,
            englishReply: englishReply,
            englishReplyJapanese: englishReplyJapanese,  // ← 追加
            katakanaReading: katakanaReading
        )
    }
}
