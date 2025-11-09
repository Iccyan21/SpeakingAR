//
//  SubtitleTranslator.swift
//  SpeakingAR
//
//  Handles language detection and translation between English and Japanese for live subtitles.
//

import Foundation
import NaturalLanguage

#if canImport(Translation)
import Translation
#endif

struct SubtitleTranslationResult {
    let translatedText: String
    let sourceLanguageCode: String
    let targetLanguageCode: String
}

enum SubtitleTranslationOutcome {
    case translated(SubtitleTranslationResult)
    case unsupportedLanguage(code: String?)
    case unavailable
}

actor SubtitleTranslator {
    private let recognizer = NLLanguageRecognizer()

    #if canImport(Translation)
    private var cachedSessions: [LanguagePair: TranslationSession] = [:]
    private var preparedPairs: Set<LanguagePair> = []
    private var preparingPairs: [LanguagePair: Task<Void, Error>] = [:]
    private var languagePreparationTasks: [String: Task<Void, Error>] = [:]
    #endif

    func translate(_ text: String) async throws -> SubtitleTranslationOutcome {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unsupportedLanguage(code: nil) }

        let detectedCode = detectLanguageCode(for: trimmed)
        guard let sourceCode = detectedCode else {
            return .unsupportedLanguage(code: nil)
        }

        guard let targetCode = targetLanguageCode(for: sourceCode) else {
            return .unsupportedLanguage(code: sourceCode)
        }

        #if canImport(Translation)
        do {
            let result = try await translate(trimmed, sourceCode: sourceCode, targetCode: targetCode)
            return .translated(result)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return .unavailable
        }
        #else
        return .unavailable
        #endif
    }

    #if canImport(Translation)
    func preloadDefaultLanguagePairs() async {
        let commonPairs = [
            LanguagePair(sourceCode: "en", targetCode: "ja"),
            LanguagePair(sourceCode: "ja", targetCode: "en")
        ]

        for pair in commonPairs {
            do {
                try await prepareModelsIfNeeded(for: pair)
            } catch is CancellationError {
                return
            } catch {
                cachedSessions[pair] = nil
                preparedPairs.remove(pair)
            }
        }
    }
    #endif

    private func detectLanguageCode(for text: String) -> String? {
        recognizer.reset()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }

    private func targetLanguageCode(for sourceCode: String) -> String? {
        switch sourceCode {
        case "en":
            return "ja"
        case "ja":
            return "en"
        default:
            return nil
        }
    }

    #if canImport(Translation)
    private func translate(_ text: String, sourceCode: String, targetCode: String) async throws -> SubtitleTranslationResult {
        if Task.isCancelled { throw CancellationError() }
        let pair = LanguagePair(sourceCode: sourceCode, targetCode: targetCode)
        let session = try await translationSession(for: pair)

        do {
            let response = try await session.translate(text)
            if Task.isCancelled { throw CancellationError() }
            return SubtitleTranslationResult(
                translatedText: response.targetText,
                sourceLanguageCode: sourceCode,
                targetLanguageCode: targetCode
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            #if DEBUG
            print("Translation failed for pair \(pair): \(error.localizedDescription)")
            #endif
            cachedSessions[pair] = nil
            preparedPairs.remove(pair)
            throw error
        }
    }

    private func translationSession(for pair: LanguagePair) async throws -> TranslationSession {
        if let existing = cachedSessions[pair] {
            return existing
        }

        try await prepareModelsIfNeeded(for: pair)

        let configuration = TranslationSession.Configuration(
            source: Locale.Language(identifier: pair.sourceCode),
            target: Locale.Language(identifier: pair.targetCode)
        )

        let session = try TranslationSession(configuration: configuration)
        cachedSessions[pair] = session
        return session
    }

    private func prepareModelsIfNeeded(for pair: LanguagePair) async throws {
        if preparedPairs.contains(pair) {
            return
        }

        if let task = preparingPairs[pair] {
            return try await task.value
        }

        let task = Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await self.prepareLanguageIfNeeded(code: pair.sourceCode) }
                group.addTask { try await self.prepareLanguageIfNeeded(code: pair.targetCode) }
                try await group.waitForAll()
            }
        }

        preparingPairs[pair] = task

        defer { preparingPairs[pair] = nil }

        do {
            try await task.value
            preparedPairs.insert(pair)
        } catch {
            preparedPairs.remove(pair)
            throw error
        }
    }

    private func prepareLanguageIfNeeded(code: String) async throws {
        let key = code.lowercased()

        if let task = languagePreparationTasks[key] {
            return try await task.value
        }

        let language = Locale.Language(identifier: code)
        let task = Task {
            let model = TranslationModel(language: language)
            if model.state != .downloaded {
                try await model.makeAvailable()
            }
        }

        languagePreparationTasks[key] = task

        defer { languagePreparationTasks[key] = nil }

        do {
            try await task.value
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw error
        }
    }
    #endif
}

private struct LanguagePair: Hashable {
    let sourceCode: String
    let targetCode: String
}
