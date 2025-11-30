//
//  PronunciationBuilderView.swift
//  SpeakingAR
//
//  Converts Japanese text into English with katakana pronunciation.
//

import SwiftUI
import UIKit

struct PronunciationBuilderView: View {
    @State private var inputText: String = ""
    @State private var suggestion: PronunciationSuggestion?
    @State private var isLoading = false
    @State private var showResult = false
    @State private var errorMessage: String?

    @StateObject private var historyStore = PronunciationHistoryStore()

    private let translator = PronunciationTranslator()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                inputSection
                outputSection
                historySection
            }
            .padding(20)
        }
        .navigationTitle("日本語→英語＆カタカナ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("日本語の文章をAIが英語とカタカナで表示")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
            Text("入力した日本語をAIが英語に翻訳し、発音の目安となるカタカナ表記とワンポイントを提案します。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("日本語を入力")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("例）助けてくれてありがとうございます")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(.horizontal, 12)
                }
                TextEditor(text: $inputText)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.secondarySystemBackground)))
            }
            Button(action: generateSuggestion) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text(isLoading ? "変換中..." : "英語と発音を作る")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.blue.opacity(0.25), radius: 10, x: 0, y: 8)
            }
            .disabled(isLoading)
        }
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("結果")
                    .font(.headline)
                Spacer()
                if showResult {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }

            if let suggestion {
                VStack(alignment: .leading, spacing: 12) {
                    resultRow(title: "English", value: suggestion.english)
                    resultRow(title: "カタカナ", value: suggestion.katakana)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ワンポイント")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(suggestion.tip)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.red.opacity(0.5)))
            } else {
                Text("変換結果がここに表示されます。")
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.secondary.opacity(0.3)))
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("履歴")
                    .font(.headline)
                Spacer()
            }

            if historyStore.items.isEmpty {
                Text("変換したフレーズの履歴がここに表示されます。")
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.secondary.opacity(0.25)))
            } else {
                VStack(spacing: 12) {
                    ForEach(historyStore.items) { entry in
                        historyRow(for: entry)
                    }
                }
            }
        }
    }

    private func resultRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
        }
    }

    private func historyRow(for entry: PronunciationHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.inputText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(entry.suggestion.english)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(entry.suggestion.katakana)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(entry.suggestion.tip)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Button(action: { copyEntry(entry) }) {
                        Label("コピー", systemImage: "doc.on.doc")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(Text("履歴をコピー: \(entry.inputText)"))

                    ShareLink(item: shareText(for: entry)) {
                        Label("共有", systemImage: "square.and.arrow.up")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(Text("履歴を共有: \(entry.inputText)"))

                    Button(role: .destructive, action: { historyStore.delete(entry) }) {
                        Label("削除", systemImage: "trash")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(Text("履歴を削除"))
                }
                .buttonStyle(.borderless)
            }

            Text(entry.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
    }

    private func shareText(for entry: PronunciationHistoryItem) -> String {
        "入力: \(entry.inputText)\nEnglish: \(entry.suggestion.english)\nカタカナ: \(entry.suggestion.katakana)\nワンポイント: \(entry.suggestion.tip)"
    }

    private func copyEntry(_ entry: PronunciationHistoryItem) {
        UIPasteboard.general.string = shareText(for: entry)
    }

    private func generateSuggestion() {
        isLoading = true
        showResult = false
        errorMessage = nil

        Task {
            do {
                let result = try await translator.translate(japaneseText: inputText)
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        suggestion = result
                        showResult = true
                    }
                    historyStore.addEntry(inputText: inputText.trimmingCharacters(in: .whitespacesAndNewlines), suggestion: result)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        suggestion = nil
                        showResult = false
                    }
                    if let localizedError = error as? LocalizedError,
                       let description = localizedError.errorDescription {
                        errorMessage = description
                    } else {
                        errorMessage = "英訳と発音の生成に失敗しました。もう一度お試しください。"
                    }
                    isLoading = false
                }
            }
        }
    }
}

struct PronunciationBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PronunciationBuilderView()
        }
    }
}
