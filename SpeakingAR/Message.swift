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
    let isProvisional: Bool

    enum CodingKeys: String, CodingKey {
        case id, timestamp, type, isProvisional
    }

    enum MessageType: Codable {
        case user(text: String)
        case ai(japaneseTranslation: String, suggestedReplies: [SuggestedReply])
    }

    init(id: UUID = UUID(), timestamp: Date = Date(), type: MessageType, isProvisional: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.isProvisional = isProvisional
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        type = try container.decode(MessageType.self, forKey: .type)
        isProvisional = try container.decodeIfPresent(Bool.self, forKey: .isProvisional) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(isProvisional, forKey: .isProvisional)
    }
}
