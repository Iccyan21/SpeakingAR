//
//  PronunciationTranslator.swift
//  SpeakingAR
//
//  Converts Japanese input into English with katakana pronunciation using the same remote AI service as AIResponder, with a local fallback.
//

import Foundation
import NaturalLanguage

enum PronunciationTranslatorError: Error {
    case emptyInput
    case invalidResponse
    case serverError(message: String)
    case httpError(statusCode: Int)
}

extension PronunciationTranslatorError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "日本語の入力が空です。テキストを入力してください。"
        case .invalidResponse:
            return "翻訳結果を読み取れませんでした。もう一度お試しください。"
        case .serverError(let message):
            return "AI サービスからエラーが返されました: \(message)"
        case .httpError(let statusCode):
            return "AI サービスとの通信に失敗しました (ステータスコード: \(statusCode))。"
        }
    }
}

struct PronunciationSuggestion: Equatable {
    let english: String
    let katakana: String
    let tip: String
}

actor PronunciationTranslator {
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
    private let fallbackBuilder = LocalPronunciationFallback()

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

    func translate(japaneseText: String) async throws -> PronunciationSuggestion {
        let trimmed = japaneseText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PronunciationTranslatorError.emptyInput }

        switch mode {
        case .remote(let apiKey):
            do {
                return try await requestRemoteTranslation(for: trimmed, apiKey: apiKey)
            } catch {
                #if DEBUG
                print("Remote pronunciation translation failed: \(error)")
                #endif
                return await fallbackBuilder.buildSuggestion(from: trimmed)
            }
        case .offline:
            return await fallbackBuilder.buildSuggestion(from: trimmed)
        }
    }

    private func requestRemoteTranslation(for japanese: String, apiKey: String) async throws -> PronunciationSuggestion {
        let systemPrompt = """
        You are an English helper for Japanese users. Convert the provided Japanese sentence into a short, natural English phrase and a katakana pronunciation guide for that English.

        Return ONLY a JSON object with the following keys:
        {
          "english_text": "English phrase",
          "katakana_reading": "Katakana pronunciation of the English phrase",
          "pronunciation_tip": "One concise Japanese tip about how to pronounce or use it"
        }

        Rules:
        - Keep the English phrase conversational and concise.
        - Katakana must reflect natural English pronunciation (not romaji). Shorten unstressed vowels and combine connected sounds.
        - If the input is unclear, guess a polite, simple phrase that fits daily conversation.
        - Output valid JSON only, with no additional commentary.
        """

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: japanese)
        ]

        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: messages,
            maxTokens: 200,
            temperature: 0.5
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PronunciationTranslatorError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            if let apiError = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw PronunciationTranslatorError.serverError(message: apiError.error.message)
            }
            throw PronunciationTranslatorError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        guard let chatResponse = try? decoder.decode(ChatResponse.self, from: data),
              let content = chatResponse.choices.first?.message?.content else {
            throw PronunciationTranslatorError.invalidResponse
        }

        guard let jsonData = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw PronunciationTranslatorError.invalidResponse
        }

        guard let english = (json["english_text"] as? String) ?? (json["english"] as? String),
              let katakana = (json["katakana_reading"] as? String) ?? (json["katakana"] as? String) else {
            throw PronunciationTranslatorError.invalidResponse
        }

        let tip = (json["pronunciation_tip"] as? String) ?? "口を大きく開けて、リズムよく発音してみましょう。"

        return PronunciationSuggestion(
            english: english.trimmingCharacters(in: .whitespacesAndNewlines),
            katakana: katakana.trimmingCharacters(in: .whitespacesAndNewlines),
            tip: tip.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

// MARK: - Local fallback
private actor LocalPronunciationFallback {
    private struct Rule {
        let keywords: [String]
        let english: String
        let tip: String
    }

    private let rules: [Rule] = [
        .init(
            keywords: ["おはよう", "朝"],
            english: "Good morning!",
            tip: "朝の挨拶は明るい声で、笑顔を添えると自然です。"
        ),
        .init(
            keywords: ["こんにちは", "昼"],
            english: "Good afternoon!",
            tip: "初対面でも使いやすいシンプルな挨拶です。"
        ),
        .init(
            keywords: ["こんばんは", "夜"],
            english: "Good evening!",
            tip: "夜の場面では落ち着いたトーンで伝えましょう。"
        ),
        .init(
            keywords: ["ありがとう", "感謝"],
            english: "Thank you so much!",
            tip: "感謝を強調したいときの定番表現です。"
        ),
        .init(
            keywords: ["すみません", "ごめん"],
            english: "I'm sorry.",
            tip: "軽い謝罪なら I'm sorry.、丁寧に伝えたいときは I apologize. も使えます。"
        ),
        .init(
            keywords: ["お願いします", "頼む", "お願い"],
            english: "Could you help me, please?",
            tip: "依頼をするときは please を添えると丁寧です。"
        ),
        .init(
            keywords: ["どこ", "場所", "道"],
            english: "Where can I find this?",
            tip: "地図や写真を見せながら聞くと伝わりやすくなります。"
        ),
        .init(
            keywords: ["いくら", "値段"],
            english: "How much is this?",
            tip: "指差しや商品名を添えるとスムーズです。"
        ),
        .init(
            keywords: ["できる", "可能"],
            english: "Is it possible?",
            tip: "相談するときのやわらかい聞き方です。"
        )
    ]

    func buildSuggestion(from japanese: String) async -> PronunciationSuggestion {
        let trimmed = japanese.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchedRule = rules.first { rule in
            rule.keywords.contains { keyword in trimmed.contains(keyword) }
        }

        let english = matchedRule?.english ?? fallbackEnglish(from: trimmed)
        let katakana = katakana(for: english)
        let tip = matchedRule?.tip ?? "シンプルな英語に言い換えて、はっきり発音してみましょう。"

        return PronunciationSuggestion(english: english, katakana: katakana, tip: tip)
    }

    private func fallbackEnglish(from japanese: String) -> String {
        switch japanese.count {
        case 1...8:
            return "Let's say it simply in English."
        default:
            return "Let's put that into simple English."
        }
    }

    private func katakana(for english: String) -> String {
        english
            .applyingTransform(.latinToKatakana, reverse: false)?
            .replacingOccurrences(of: "・", with: "・") ?? english
    }
}
