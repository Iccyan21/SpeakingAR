//
//  SubtitleTranslator.swift
//  SpeakingAR
//
//  Handles language detection and translation between English and Japanese for live subtitles.
//

import Foundation
import NaturalLanguage

#if canImport(Translate)
import Translate
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

    #if canImport(Translate)
    private var cachedSessions: [LanguagePair: TranslationSession] = [:]
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

        #if canImport(Translate)
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

    #if canImport(Translate)
    private func translate(_ text: String, sourceCode: String, targetCode: String) async throws -> SubtitleTranslationResult {
        if Task.isCancelled { throw CancellationError() }
        let pair = LanguagePair(sourceCode: sourceCode, targetCode: targetCode)
        let session = try translationSession(for: pair)
        let response = try await session.translate(text)
        if Task.isCancelled { throw CancellationError() }
        return SubtitleTranslationResult(
            translatedText: response.targetText,
            sourceLanguageCode: sourceCode,
            targetLanguageCode: targetCode
        )
    }

    private func translationSession(for pair: LanguagePair) throws -> TranslationSession {
        if let existing = cachedSessions[pair] {
            return existing
        }

        let configuration = TranslationSession.Configuration(
            source: Locale.Language(identifier: pair.sourceCode),
            target: Locale.Language(identifier: pair.targetCode)
        )
        let session = try TranslationSession(configuration: configuration)
        cachedSessions[pair] = session
        return session
    }
    #endif
}

private struct LanguagePair: Hashable {
    let sourceCode: String
    let targetCode: String
}
