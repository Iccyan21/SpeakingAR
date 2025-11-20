//
//  PronunciationBuilderView.swift
//  SpeakingAR
//
//  Created to convert Japanese text into simple English phrases with katakana guides.
//

import SwiftUI

struct PronunciationSuggestion: Equatable {
    let english: String
    let katakana: String
    let tip: String
}

actor PronunciationCoach {
    private struct Rule {
        let keywords: [String]
        let english: String
        let tip: String
    }

    private let rules: [Rule] = [
        .init(
            keywords: ["おはよう", "朝"],
            english: "Good morning!",
            tip: "朝の挨拶は明るい声で、笑顔を添えると自然です。"
        ),
        .init(
            keywords: ["こんにちは", "昼"],
            english: "Good afternoon!",
            tip: "初対面でも使いやすいシンプルな挨拶です。"
        ),
        .init(
            keywords: ["こんばんは", "夜"],
            english: "Good evening!",
            tip: "夜の場面では落ち着いたトーンで伝えましょう。"
        ),
        .init(
            keywords: ["ありがとう", "感謝"],
            english: "Thank you so much!",
            tip: "感謝を強調したいときの定番表現です。"
        ),
        .init(
            keywords: ["すみません", "ごめん"],
            english: "I'm sorry.",
            tip: "軽い謝罪なら I'm sorry.、丁寧に伝えたいときは I apologize. も使えます。"
        ),
        .init(
            keywords: ["お願いします", "頼む", "お願い"],
            english: "Could you help me, please?",
            tip: "依頼をするときは please を添えると丁寧です。"
        ),
        .init(
            keywords: ["どこ", "場所", "道"],
            english: "Where can I find this?",
            tip: "地図や写真を見せながら聞くと伝わりやすくなります。"
        ),
        .init(
            keywords: ["いくら", "値段"],
            english: "How much is this?",
            tip: "指差しや商品名を添えるとスムーズです。"
        ),
        .init(
            keywords: ["できる", "可能"],
            english: "Is it possible?",
            tip: "相談するときのやわらかい聞き方です。"
        )
    ]

    func buildSuggestion(from japanese: String) async -> PronunciationSuggestion? {
        let trimmed = japanese.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let matchedRule = rules.first { rule in
            rule.keywords.contains { keyword in trimmed.contains(keyword) }
        }

        let english = matchedRule?.english ?? fallbackEnglish(from: trimmed)
        let katakana = english
            .applyingTransform(.latinToKatakana, reverse: false)?
            .replacingOccurrences(of: "・", with: "・") ?? english
        let tip = matchedRule?.tip ?? "シンプルな英語に言い換えて、はっきり発音してみましょう。"

        return PronunciationSuggestion(english: english, katakana: katakana, tip: tip)
    }

    private func fallbackEnglish(from japanese: String) -> String {
        switch japanese.count {
        case 1...8:
            return "Let's say it simply in English."
        default:
            return "Let's put that into simple English."
        }
    }
}

struct PronunciationBuilderView: View {
    @State private var inputText: String = ""
    @State private var suggestion: PronunciationSuggestion?
    @State private var isLoading = false
    @State private var showResult = false

    private let coach = PronunciationCoach()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                inputSection
                outputSection
            }
            .padding(20)
        }
        .navigationTitle("日本語→英語＆カタカナ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("日本語の文章を英語とカタカナで表示")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
            Text("入力した日本語をシンプルな英語に変換し、発音の目安となるカタカナ表記を提案します。")
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
            } else {
                Text("変換結果がここに表示されます。")
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.secondary.opacity(0.3)))
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

    private func generateSuggestion() {
        isLoading = true
        showResult = false

        Task {
            let result = await coach.buildSuggestion(from: inputText)
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    suggestion = result
                    showResult = result != nil
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
