//
//  Message.swift
//  SpeakingAR
//

import Foundation

struct SuggestedReply: Identifiable, Codable, Hashable {
    let id = UUID()
    let tone: ReplyTone
    let englishText: String
    let japaneseTranslation: String
    let katakanaReading: String
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case tone, englishText, japaneseTranslation, katakanaReading, explanation
    }
}

enum ReplyTone: String, Codable {
    case positive
    case neutral
    case negative
}

struct Message: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: MessageType

    enum MessageType: Codable {
        case user(text: String)
        case ai(japaneseTranslation: String, suggestedReplies: [SuggestedReply], isStreamingReplies: Bool)

        private enum CodingKeys: String, CodingKey {
            case role
            case content
            case japaneseTranslation
            case suggestedReplies
            case isStreamingReplies
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .user(let text):
                try container.encode("user", forKey: .role)
                try container.encode(text, forKey: .content)
            case .ai(let japaneseTranslation, let suggestedReplies, let isStreamingReplies):
                try container.encode("ai", forKey: .role)
                try container.encode(japaneseTranslation, forKey: .japaneseTranslation)
                try container.encode(suggestedReplies, forKey: .suggestedReplies)
                try container.encode(isStreamingReplies, forKey: .isStreamingReplies)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let role = try container.decode(String.self, forKey: .role)

            switch role {
            case "user":
                let text = try container.decode(String.self, forKey: .content)
                self = .user(text: text)
            case "ai":
                let japaneseTranslation = try container.decode(String.self, forKey: .japaneseTranslation)
                let replies = try container.decodeIfPresent([SuggestedReply].self, forKey: .suggestedReplies) ?? []
                let isStreaming = try container.decodeIfPresent(Bool.self, forKey: .isStreamingReplies) ?? false
                self = .ai(
                    japaneseTranslation: japaneseTranslation,
                    suggestedReplies: replies,
                    isStreamingReplies: isStreaming
                )
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unsupported message role: \(role)"
                    )
                )
            }
        }
    }

    init(id: UUID = UUID(), timestamp: Date = Date(), type: MessageType) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
    }
}
