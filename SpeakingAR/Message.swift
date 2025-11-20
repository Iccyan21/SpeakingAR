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
    }

    init(id: UUID = UUID(), timestamp: Date = Date(), type: MessageType) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
    }
}
