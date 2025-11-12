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
        You are an English communication coach for Japanese learners.

        Your goal is to help the user decide how to reply naturally and effectively in English conversations.

        The user will input an English sentence that someone else said to them.  
        You must output a JSON object containing:

        1. "japanese_translation": A natural Japanese translation of what the other person said.
        2. "suggested_replies": An object containing 3 reply options with different tones:
        - "positive": a friendly, upbeat, or optimistic reply
        - "neutral": a balanced, calm, or typical reply
        - "negative": a reserved, tired, or slightly downbeat reply
        3. "reply_explanations": Japanese explanations for each reply (describe the nuance and when to use it)
        4. "katakana_readings": Katakana pronunciation guides for each reply

        Example format:
        {
        "japanese_translation": "最近どうしてる？",
        "suggested_replies": {
            "positive": "I've been really good, thanks for asking!",
            "neutral": "Pretty good, just the usual stuff.",
            "negative": "Not great, honestly. It’s been a bit rough lately."
        },
        "reply_explanations": {
            "positive": "とても元気で前向きな印象を与える返答。カジュアルで明るいトーン。",
            "neutral": "普通に元気だよ、という自然なトーン。会話の定番表現。",
            "negative": "少し疲れている、しんどいという正直なトーン。親しい人に使いやすい。"
        },
        "katakana_readings": {
            "positive": "アイヴ ビーン リアリー グッド、サンクス フォー アスキング！",
            "neutral": "プリティ グッド、ジャスト ザ ユージュアル スタッフ。",
            "negative": "ノット グレイト、オネスリー。イッツ ビーン ア ビット ラフ レイトリー。"
        }
        }

        Rules:
        - Each reply should sound natural and conversational in English.
        - Keep replies short (1–2 sentences max).
        - Match the emotional tone clearly (positive / neutral / negative).
        - Explanations and translations should be natural in Japanese.
        - Only output valid JSON, nothing else.
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
