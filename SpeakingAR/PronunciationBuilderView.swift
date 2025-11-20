//
//  PronunciationBuilderView.swift
//  SpeakingAR
//
//  Converts Japanese text into English with katakana pronunciation.
//

import SwiftUI

struct PronunciationBuilderView: View {
    @State private var inputText: String = ""
    @State private var suggestion: PronunciationSuggestion?
    @State private var isLoading = false
    @State private var showResult = false
    @State private var errorMessage: String?

    private let translator = PronunciationTranslator()
    private let samples = [
        "道に迷いました、助けてください",
        "タクシーを呼んでもらえますか",
        "クレジットカードは使えますか",
        "予約している◯◯です"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                statusCard
                inputSection
                helperChips
                outputSection
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("日本語→英語＆カタカナ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("誰でも迷わず使える翻訳サポート")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
            Text("日本語を入れるだけで、すぐに通じる短い英語とカタカナの読み方を提案。準備や学習なしで、今すぐ伝えたい気持ちに応えます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title3.weight(.bold))
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.blue.opacity(0.12)))

            VStack(alignment: .leading, spacing: 4) {
                Text("AIが短く自然な表現に整えます")
                    .font(.subheadline.weight(.semibold))
                Text("敬語や長い文章でも安心。アプリがやさしい英語にまとめ、カタカナで発音の目安も表示します。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 6)
        )
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
                    .textInputAutocapitalization(.never)
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

    private var helperChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("すぐ使える例")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            FlowLayout(alignment: .leading, spacing: 8) {
                ForEach(samples, id: \.self) { text in
                    Button {
                        inputText = text
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                            Text(text)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.blue.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
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

// MARK: - Flow layout utility for chips
struct FlowLayout<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    @ViewBuilder var content: Content

    init(alignment: HorizontalAlignment = .leading, spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            content
                .alignmentGuide(.leading) { dimension in
                    if width + dimension.width > geometry.size.width {
                        width = 0
                        height -= dimension.height + spacing
                    }
                    let result = width
                    width += dimension.width + spacing
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = height
                    return result
                }
        }
    }
}
