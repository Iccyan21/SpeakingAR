import Foundation

struct PronunciationHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let inputText: String
    let suggestion: PronunciationSuggestion
    let createdAt: Date

    init(id: UUID = UUID(), inputText: String, suggestion: PronunciationSuggestion, createdAt: Date = Date()) {
        self.id = id
        self.inputText = inputText
        self.suggestion = suggestion
        self.createdAt = createdAt
    }
}

@MainActor
final class PronunciationHistoryStore: ObservableObject {
    @Published private(set) var items: [PronunciationHistoryItem] = []

    private let storageKey = "pronunciation_history_items"
    private let maxEntries = 50

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([PronunciationHistoryItem].self, from: data)
            items = decoded.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            #if DEBUG
            print("Failed to decode pronunciation history: \(error)")
            #endif
            items = []
        }
    }

    func addEntry(inputText: String, suggestion: PronunciationSuggestion) {
        var updated = items
        updated.insert(PronunciationHistoryItem(inputText: inputText, suggestion: suggestion), at: 0)
        if updated.count > maxEntries {
            updated = Array(updated.prefix(maxEntries))
        }
        items = updated
        persist()
    }

    func delete(_ entry: PronunciationHistoryItem) {
        items.removeAll { $0.id == entry.id }
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            #if DEBUG
            print("Failed to encode pronunciation history: \(error)")
            #endif
        }
    }
}
