//
//  ChatHistoryStore.swift
//  SpeakingAR
//

import Foundation

actor ChatHistoryStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default, fileName: String = "chat_history.json") {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        self.fileURL = documentsDirectory.appendingPathComponent(fileName)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func load() -> [Message] {
        do {
            let data = try Data(contentsOf: fileURL)
            let messages = try decoder.decode([Message].self, from: data)
            return messages
        } catch {
            return []
        }
    }

    func save(_ messages: [Message]) {
        do {
            let data = try encoder.encode(messages)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            #if DEBUG
            print("Failed to save chat history: \(error)")
            #endif
        }
    }
}
