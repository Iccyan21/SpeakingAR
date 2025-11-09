//
//  SubtitleTranslator.swift
//  SpeakingAR
//

import Foundation
import NaturalLanguage

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

    func translate(_ text: String) async throws -> SubtitleTranslationOutcome {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unsupportedLanguage(code: nil) }

        // 言語を検出
        let detectedCode = detectLanguageCode(for: trimmed)
        guard let sourceCode = detectedCode else {
            return .unsupportedLanguage(code: nil)
        }

        // 翻訳先の言語を決定
        guard let targetCode = targetLanguageCode(for: sourceCode) else {
            return .unsupportedLanguage(code: sourceCode)
        }

        // Translation フレームワークは使えないので unavailable を返す
        // 将来的に他の翻訳サービス（Google Translate API など）を使う場合はここに実装
        return .unavailable
    }

    func preloadDefaultLanguagePairs() async {
        // 何もしない（将来の拡張用）
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
}

private struct LanguagePair: Hashable {
    let sourceCode: String
    let targetCode: String
}
