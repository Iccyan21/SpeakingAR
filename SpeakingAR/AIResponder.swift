//
//  AIResponder.swift
//  SpeakingAR
//

import Foundation
import CoreFoundation
import NaturalLanguage

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
        apiKey: String? = "OPENAI_API_KEY",
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
           Each reply MUST be an object with:
            {
                "english": "reply in English",
                "japanese_translation": "natural Japanese translation of the reply",
                "katakana_reading": "katakana pronunciation of the reply",
                "explanation": "Japanese explanation of nuance and when to use it"
            }
        3. Katakana pronunciation guides must reflect **natural English pronunciation**, not romaji reading.
            - Omit unnatural syllables (like “ドゥーイング”) and use pronunciation-based forms (like “ドゥイン”).
            - Reflect connected speech (like “アイヴィン” for “I’ve been”).

        Example format:
        {
          "japanese_translation": "最近どうしてる？",
          "suggested_replies": {
            "positive": {
              "english": "I've been really good, thanks for asking!",
              "japanese_translation": "すごく元気だよ、聞いてくれてありがとう！",
              "katakana_reading": "アイヴ ビーン リアリー グッド、サンクス フォー アスキング！",
              "explanation": "とても元気で前向きな印象を与える返答。カジュアルで明るいトーン。"
            },
            "neutral": {
              "english": "Pretty good, just the usual stuff.",
              "japanese_translation": "まあまあかな。いつも通りだよ。",
              "katakana_reading": "プリティ グッド、ジャスト ザ ユージュアル スタッフ。",
              "explanation": "普通に元気だよ、という自然なトーン。会話の定番表現。"
            },
            "negative": {
              "english": "Not great, honestly. It's been a bit rough lately.",
              "japanese_translation": "正直あまり良くないんだ。最近ちょっと大変で。",
              "katakana_reading": "ノット グレイト、オネスリー。イッツ ビーン ア ビット ラフ レイトリー。",
              "explanation": "少し疲れている、しんどいという正直なトーン。親しい人に使いやすい。"
            }
          }
        }

        Rules:
        - Each reply should sound natural and conversational in English.
        - Keep replies short (1–2 sentences max).
        - Match the emotional tone clearly (positive / neutral / negative).
        - Japanese translations and explanations should be natural and easy to understand.
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
              let suggestedRepliesDict = json["suggested_replies"] as? [String: [String: Any]] else {
            throw AIResponderError.invalidResponse
        }

        var replies: [AIReply] = []

        for tone in ["positive", "neutral", "negative"] {
            guard let replyDict = suggestedRepliesDict[tone],
                  let englishText = replyDict["english"] as? String,
                  let japaneseReply = replyDict["japanese_translation"] as? String,
                  let katakana = replyDict["katakana_reading"] as? String,
                  let explanation = replyDict["explanation"] as? String,
                  let replyTone = ReplyTone(rawValue: tone) else {
                continue
            }

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
    private enum TranslationConfidence {
        case high
        case medium
        case low
    }

    private struct TranslationResult {
        let text: String
        let confidence: TranslationConfidence
    }

    private enum ConversationContext {
        case greeting
        case statusCheck
        case invitation
        case request
        case gratitude
        case apology
        case schedule
        case question
        case generic
    }

    private struct ReplySet {
        let positive: ReplyContent
        let neutral: ReplyContent
        let negative: ReplyContent
    }

    private struct ReplyContent {
        let english: String
        let japanese: String
        let explanation: String
    }

    private struct TranslationRule {
        let keyword: String
        let translation: String
    }

    private let translationRules: [TranslationRule] = [
        .init(keyword: "how are you", translation: "最近どうしてる？"),
        .init(keyword: "how's it going", translation: "調子はどう？"),
        .init(keyword: "what's up", translation: "何か良いことあった？"),
        .init(keyword: "nice to meet you", translation: "はじめまして！"),
        .init(keyword: "can you", translation: "〜してくれる？というお願い"),
        .init(keyword: "could you", translation: "〜してもらえる？という丁寧なお願い"),
        .init(keyword: "do you want", translation: "〜したい？という誘い"),
        .init(keyword: "would you like", translation: "〜いかが？という丁寧な誘い"),
        .init(keyword: "let's", translation: "一緒にやろうという提案"),
        .init(keyword: "meeting", translation: "打ち合わせについての話題"),
        .init(keyword: "deadline", translation: "締め切りの話題"),
        .init(keyword: "thank", translation: "ありがとうという気持ち"),
        .init(keyword: "sorry", translation: "謝罪のメッセージ")
    ]

    private let lexicalDictionary: [String: String] = [
        "hello": "こんにちは",
        "hi": "やあ",
        "thanks": "ありがとう",
        "thank": "ありがとう",
        "you": "あなた",
        "sorry": "ごめん",
        "meeting": "ミーティング",
        "deadline": "締め切り",
        "tomorrow": "明日",
        "today": "今日",
        "later": "あとで",
        "maybe": "たぶん",
        "please": "お願いします",
        "help": "助ける",
        "plan": "計画",
        "join": "参加",
        "come": "来る",
        "coffee": "コーヒー",
        "lunch": "ランチ",
        "dinner": "ディナー"
    ]

    private let contextKeywords: [(ConversationContext, [String])] = [
        (.greeting, ["hello", "hi", "nice to meet you", "good morning", "good evening"]),
        (.statusCheck, ["how are you", "how's it going", "what's up"]),
        (.invitation, ["let's", "would you like", "do you want", "join", "come over"]),
        (.request, ["can you", "could you", "please", "help", "need you to"]),
        (.gratitude, ["thank", "thanks", "appreciate"]),
        (.apology, ["sorry", "apologize", "my bad"]),
        (.schedule, ["meeting", "deadline", "schedule", "tomorrow", "later"])
    ]

    private let replySets: [ConversationContext: ReplySet] = {
        let generic = ReplySet(
            positive: .init(
                english: "Sounds good! I'm interested in what you mentioned.",
                japanese: "いいね！その話題に興味あるよ。",
                explanation: "前向きに話に乗りたいときのシンプルな返答。"
            ),
            neutral: .init(
                english: "Got it. Let me take a moment to think about it.",
                japanese: "了解。少し考えさせてね。",
                explanation: "一度受け止めてから返したい時の落ち着いたトーン。"
            ),
            negative: .init(
                english: "I might have to pass this time, but thanks for telling me.",
                japanese: "今回は遠慮しようかな。でも話してくれてありがとう。",
                explanation: "控えめに断りたいときの表現。"
            )
        )

        return [
            .greeting: ReplySet(
                positive: .init(
                    english: "Great to see you! How have you been?",
                    japanese: "会えて嬉しいよ！最近どうしてた？",
                    explanation: "明るく距離を縮めたいときの挨拶。"
                ),
                neutral: .init(
                    english: "Nice to see you too. How's everything going?",
                    japanese: "こちらこそ、調子はどう？",
                    explanation: "落ち着いた挨拶で自然に近況を聞ける言い回し。"
                ),
                negative: .init(
                    english: "Hey, it's been a busy day, but nice to see you.",
                    japanese: "今日はちょっとバタバタだけど、会えてよかった。",
                    explanation: "少し疲れているときの正直な挨拶。"
                )
            ),
            .statusCheck: ReplySet(
                positive: .init(
                    english: "I'm doing great! Thanks for asking.",
                    japanese: "すごく元気！聞いてくれてありがとう。",
                    explanation: "元気さを伝えて会話を弾ませる返答。"
                ),
                neutral: .init(
                    english: "Pretty good, just keeping busy as usual.",
                    japanese: "まあまあかな。いつも通り忙しくしてるよ。",
                    explanation: "日常的な調子を伝える定番フレーズ。"
                ),
                negative: .init(
                    english: "Honestly, it's been a bit rough, but I'm hanging in there.",
                    japanese: "正直ちょっと大変だけど、なんとかやってるよ。",
                    explanation: "疲れているけど会話を続けたい時の率直な返答。"
                )
            ),
            .invitation: ReplySet(
                positive: .init(
                    english: "That sounds fun! Count me in.",
                    japanese: "楽しそう！ぜひ参加させて。",
                    explanation: "誘いに明るく乗りたいときに使いやすい。"
                ),
                neutral: .init(
                    english: "Let me check my schedule, but I'm interested.",
                    japanese: "予定を確認するけど、行きたいと思ってるよ。",
                    explanation: "前向きさを保ちつつ予定を確認したいとき。"
                ),
                negative: .init(
                    english: "I appreciate the invite, but I might have to skip this time.",
                    japanese: "誘ってくれて嬉しいけど、今回は難しいかも。",
                    explanation: "丁寧に断るときの柔らかい言い方。"
                )
            ),
            .request: ReplySet(
                positive: .init(
                    english: "Sure thing! Let me help you out.",
                    japanese: "もちろん！手伝わせて。",
                    explanation: "すぐ手を貸したいときの積極的な返答。"
                ),
                neutral: .init(
                    english: "I can take a look. When do you need it?",
                    japanese: "見てみるよ。いつまでに必要？",
                    explanation: "依頼内容を確認しながら応じるときの表現。"
                ),
                negative: .init(
                    english: "I'd love to help, but my schedule is packed right now.",
                    japanese: "手伝いたいけど、今は予定がいっぱいなんだ。",
                    explanation: "無理をせず丁寧に断る言い回し。"
                )
            ),
            .gratitude: ReplySet(
                positive: .init(
                    english: "Happy to help anytime!",
                    japanese: "いつでも手伝うよ！",
                    explanation: "感謝されたときに気持ちよく返す一言。"
                ),
                neutral: .init(
                    english: "No problem at all. Glad it worked out.",
                    japanese: "全然大丈夫。うまくいってよかった。",
                    explanation: "落ち着いたトーンで返すお礼への返事。"
                ),
                negative: .init(
                    english: "It was nothing big, but thanks for saying that.",
                    japanese: "大したことないけど、そう言ってもらえて嬉しい。",
                    explanation: "控えめに受け止めたいときの返答。"
                )
            ),
            .apology: ReplySet(
                positive: .init(
                    english: "No worries at all. We're totally fine.",
                    japanese: "全然気にしないで。何も問題ないよ。",
                    explanation: "相手を安心させたいときの優しい返答。"
                ),
                neutral: .init(
                    english: "I understand. Thanks for letting me know.",
                    japanese: "わかったよ。知らせてくれてありがとう。",
                    explanation: "落ち着いて受け止めたいときの言い方。"
                ),
                negative: .init(
                    english: "I appreciate the apology, but let's fix it soon.",
                    japanese: "謝ってくれてありがとう。早めにリカバリーしよう。",
                    explanation: "少し厳しめに現実的な対応を促したいとき。"
                )
            ),
            .schedule: ReplySet(
                positive: .init(
                    english: "Let's lock in a time. I'm flexible this week.",
                    japanese: "今週は柔軟に動けるから、時間を決めよう。",
                    explanation: "日程調整に積極的な姿勢を示す表現。"
                ),
                neutral: .init(
                    english: "How about Thursday afternoon?",
                    japanese: "木曜の午後はどう？",
                    explanation: "具体的な案を落ち着いて出したいとき。"
                ),
                negative: .init(
                    english: "This week is tough, but I can propose a new time soon.",
                    japanese: "今週は難しいけど、別日をすぐ提案するね。",
                    explanation: "難しい状況でも前向きさを保つ返答。"
                )
            ),
            .question: ReplySet(
                positive: .init(
                    english: "Great question! Here's what I think...",
                    japanese: "良い質問だね！私の考えは…",
                    explanation: "質問に熱心に答えるときの導入フレーズ。"
                ),
                neutral: .init(
                    english: "Let me think for a second before I answer.",
                    japanese: "少し考えてから答えるね。",
                    explanation: "落ち着いて回答したいとき。"
                ),
                negative: .init(
                    english: "I'm not sure yet, but I'll get back to you soon.",
                    japanese: "まだ分からないけど、すぐ返事するね。",
                    explanation: "即答できないときの丁寧な返し方。"
                )
            ),
            .generic: generic
        ]
    }()

    func buildResponse(for transcript: String) -> AIResponseData {
        let normalized = transcript.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let translation = fallbackJapaneseTranslation(for: normalized)
        let contextNote = contextSnippet(from: normalized)
        let context = conversationContext(for: normalized)

        let replies = contextualReplies(
            for: context,
            confidence: translation.confidence,
            contextNote: contextNote
        )

        return AIResponseData(
            japaneseTranslation: translation.text,
            suggestedReplies: replies
        )
    }

    private func fallbackJapaneseTranslation(for text: String) -> TranslationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return TranslationResult(text: "（参考訳）内容が検出できませんでした。", confidence: .low)
        }

        if containsJapaneseCharacters(in: trimmed) {
            return TranslationResult(text: trimmed, confidence: .high)
        }

        let normalized = trimmed
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        if let hit = translationRules.first(where: { normalized.contains($0.keyword) }) {
            return TranslationResult(text: hit.translation, confidence: .high)
        }

        if let lexical = lexicalTranslation(for: normalized) {
            return TranslationResult(text: lexical, confidence: .medium)
        }

        return TranslationResult(text: "（参考訳）\(trimmed)", confidence: .low)
    }

    private func lexicalTranslation(for normalized: String) -> String? {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = normalized

        var translatedWords: [String] = []
        tokenizer.enumerateTokens(in: normalized.startIndex..<normalized.endIndex) { range, _ in
            let word = String(normalized[range])
            if let translation = lexicalDictionary[word] {
                translatedWords.append(translation)
            }
            return true
        }

        guard !translatedWords.isEmpty else { return nil }
        return translatedWords.joined(separator: "・")
    }

    private func contextSnippet(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let limited = trimmed.prefix(32)
        return limited.count < trimmed.count ? "\(limited)…" : String(limited)
    }

    private func conversationContext(for text: String) -> ConversationContext {
        let normalized = text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        for (context, keywords) in contextKeywords {
            if keywords.contains(where: { normalized.contains($0) }) {
                return context
            }
        }

        if normalized.contains("?") {
            return .question
        }

        return .generic
    }

    private func contextualReplies(for context: ConversationContext, confidence: TranslationConfidence, contextNote: String) -> [AIReply] {
        guard confidence != .low else { return [] }
        guard let replySet = replySets[context] ?? replySets[.generic] else { return [] }

        let positive = makeReply(
            tone: .positive,
            content: replySet.positive,
            contextNote: contextNote
        )

        let neutral = makeReply(
            tone: .neutral,
            content: replySet.neutral,
            contextNote: contextNote
        )

        let negative = makeReply(
            tone: .negative,
            content: replySet.negative,
            contextNote: contextNote
        )

        return [positive, neutral, negative]
    }

    private func explanation(for context: String, baseText: String) -> String {
        guard !context.isEmpty else { return baseText }
        return "\(baseText) 相手の発言: \(context)"
    }

    private func containsJapaneseCharacters(in text: String) -> Bool {
        text.range(of: #"[一-龥ぁ-ゔゞァ-ヾ々ー]"#, options: .regularExpression) != nil
    }

    private func makeReply(tone: ReplyTone, content: ReplyContent, contextNote: String) -> AIReply {
        AIReply(
            tone: tone,
            englishText: content.english,
            japaneseTranslation: content.japanese,
            katakanaReading: katakanaReading(for: content.english),
            explanation: explanation(for: contextNote, baseText: content.explanation)
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
