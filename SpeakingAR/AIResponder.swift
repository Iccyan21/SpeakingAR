//
//  AIResponder.swift
//  SpeakingAR
//

import Foundation
import CoreFoundation

enum AIResponderError: Error {
    case invalidResponse
    case serverError(message: String)
    case httpError(statusCode: Int)
}

extension AIResponderError: LocalizedError {
    var errorDescription: String? {
        switch self {
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
    let suggestedReplies: [AIReply]  // 3つの返答候補
}

struct AIReply: Codable {
    let tone: ReplyTone
    let englishText: String
    let japaneseTranslation: String
    let katakanaReading: String
    let explanation: String
}

actor AIResponder {
    private enum Mode {
        case remote(apiKey: String)
        case offline
    }

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

    private let mode: Mode
    private let endpoint: URL
    private let urlSession: URLSession
    private let fallbackBuilder = LocalResponseBuilder()

    init(
        apiKey: String? = "API_KEY",
        endpoint: URL = URL(string: "https://api.openai.com/v1/chat/completions")!,
        urlSession: URLSession = .shared
    ) {
        if let rawKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines),
           !rawKey.isEmpty {
            self.mode = .remote(apiKey: rawKey)
        } else {
            self.mode = .offline
        }
        self.endpoint = endpoint
        self.urlSession = urlSession
    }

    func generateResponse(for transcript: String) async throws -> AIResponseData {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AIResponderError.invalidResponse }

        switch mode {
        case .remote(let apiKey):
            do {
                return try await requestRemoteResponse(for: trimmed, apiKey: apiKey)
            } catch {
                #if DEBUG
                print("Remote AI call failed, falling back to local response: \(error)")
                #endif
                return fallbackBuilder.buildResponse(for: trimmed)
            }
        case .offline:
            return fallbackBuilder.buildResponse(for: trimmed)
        }
    }

    private func requestRemoteResponse(for transcript: String, apiKey: String) async throws -> AIResponseData {
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
            ChatMessage(role: "user", content: transcript)
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

        guard let jsonData = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let japaneseTranslation = json["japanese_translation"] as? String,
              let suggestedRepliesDict = json["suggested_replies"] as? [String: String],
              let replyExplanations = json["reply_explanations"] as? [String: String],
              let katakanaReadings = json["katakana_readings"] as? [String: String] else {
            throw AIResponderError.invalidResponse
        }

        var replies: [AIReply] = []

        for tone in ["positive", "neutral", "negative"] {
            guard let englishText = suggestedRepliesDict[tone],
                  let explanation = replyExplanations[tone],
                  let katakana = katakanaReadings[tone],
                  let replyTone = ReplyTone(rawValue: tone) else {
                continue
            }

            let japaneseReply = explanation.components(separatedBy: "。").first ?? explanation

            replies.append(AIReply(
                tone: replyTone,
                englishText: englishText,
                japaneseTranslation: japaneseReply,
                katakanaReading: katakana,
                explanation: explanation
            ))
        }

        guard !replies.isEmpty else {
            throw AIResponderError.invalidResponse
        }

        return AIResponseData(
            japaneseTranslation: japaneseTranslation,
            suggestedReplies: replies
        )
    }
}

// MARK: - Local fallback generator
private struct LocalResponseBuilder {
    private let templateTranslations: [(keyword: String, translation: String)] = [
        ("how are you", "最近どうしてる？"),
        ("what's up", "何か良いことあった？"),
        ("where are you", "今どこにいるの？"),
        ("can you", "〜してくれる？というお願い"),
        ("do you want", "〜したい？という誘い"),
        ("let's", "一緒にやろうという提案"),
        ("meeting", "打ち合わせについての話題"),
        ("deadline", "締め切りの話題")
    ]

    func buildResponse(for transcript: String) -> AIResponseData {
        let normalized = transcript.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let japaneseMeaning = fallbackJapaneseTranslation(for: normalized)
        let contextNote = contextSnippet(from: normalized)

        let positive = makeReply(
            tone: .positive,
            english: "That sounds great! I'd love to follow up soon.",
            japanese: "すごく良さそう！ぜひ前向きに進めたいな。",
            explanation: explanation(for: contextNote, baseText: "明るくテンポよく相手の話題に乗りたいときの返答。")
        )

        let neutral = makeReply(
            tone: .neutral,
            english: "Thanks for letting me know. Let me think about it for a moment.",
            japanese: "教えてくれてありがとう。ちょっと考えさせてね。",
            explanation: explanation(for: contextNote, baseText: "落ち着いたトーンで、少し考える余裕を示すときに使える返答。")
        )

        let negative = makeReply(
            tone: .negative,
            english: "I might have to pass for now, but thanks for asking.",
            japanese: "今は遠慮しようかな。でも誘ってくれてありがとう。",
            explanation: explanation(for: contextNote, baseText: "控えめに断りたいときの丁寧な表現。")
        )

        return AIResponseData(
            japaneseTranslation: japaneseMeaning,
            suggestedReplies: [positive, neutral, negative]
        )
    }

    private func fallbackJapaneseTranslation(for text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "（参考訳）内容が検出できませんでした。"
        }

        if containsJapaneseCharacters(in: trimmed) {
            return trimmed
        }

        let normalized = trimmed
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        if let hit = templateTranslations.first(where: { normalized.contains($0.keyword) }) {
            return hit.translation
        }

        return "（参考訳）\(trimmed)"
    }

    private func contextSnippet(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let limited = trimmed.prefix(32)
        return limited.count < trimmed.count ? "\(limited)…" : String(limited)
    }

    private func explanation(for context: String, baseText: String) -> String {
        guard !context.isEmpty else { return baseText }
        return "\(baseText) 相手の発言: \(context)"
    }

    private func containsJapaneseCharacters(in text: String) -> Bool {
        text.range(of: #"[一-龥ぁ-ゔゞァ-ヾ々ー]"#, options: .regularExpression) != nil
    }

    private func makeReply(tone: ReplyTone, english: String, japanese: String, explanation: String) -> AIReply {
        AIReply(
            tone: tone,
            englishText: english,
            japaneseTranslation: japanese,
            katakanaReading: katakanaReading(for: english),
            explanation: explanation
        )
    }

    private func katakanaReading(for text: String) -> String {
        let mutableString = NSMutableString(string: text) as CFMutableString
        if CFStringTransform(mutableString, nil, kCFStringTransformLatinKatakana, false) {
            return (mutableString as String).uppercased()
        } else {
            return text
        }
    }
}
