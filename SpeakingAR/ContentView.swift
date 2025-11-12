//
//  ContentView.swift
//  SpeakingAR
//
//  Created by 水原樹 on 2025/11/03.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var transcriber = LiveTranscriber()

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                ChatHeader(isRecording: transcriber.isRecording)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // チャット履歴
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if transcriber.messages.isEmpty {
                                EmptyStateView()
                            } else {
                                ForEach(transcriber.messages) { message in
                                    MessageRow(message: message)
                                        .id(message.id)
                                }
                            }

                            // 録音中の一時的な表示
                            if transcriber.isRecording && !transcriber.currentTranscript.isEmpty {
                                MessageRow(
                                    message: Message(
                                        type: .user(text: transcriber.currentTranscript)
                                    )
                                )
                                .opacity(0.6)
                            }

                            // AI応答生成中の表示
                            if transcriber.isGeneratingAIResponse {
                                AIThinkingView()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: transcriber.messages.count) { _ in
                        if let lastMessage = transcriber.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // 録音ボタン
                RecordButton(isRecording: transcriber.isRecording) {
                    if transcriber.isRecording {
                        transcriber.stopTranscribing(userInitiated: true)
                    } else {
                        transcriber.startTranscribing()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .onAppear {
            transcriber.requestPermissionsIfNeeded()
        }
    }
}

// MARK: - Chat Header
private struct ChatHeader: View {
    let isRecording: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("English Chat")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Circle()
                        .fill(isRecording ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)

                    Text(isRecording ? "リスニング中" : "待機中")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Empty State
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text("マイクボタンを押して\n英会話を開始")
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - AI Thinking View
private struct AIThinkingView: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white.opacity(0.7))

            Text("AI が考え中...")
                .font(.callout)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Message Row
private struct MessageRow: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            switch message.type {
            case .user(let text):
                Spacer(minLength: 50)
                UserMessageBubble(text: text, timestamp: message.timestamp)

            case .ai(let japaneseTranslation, let suggestedReplies):
                AIMessageBubble(
                    japaneseTranslation: japaneseTranslation,
                    suggestedReplies: suggestedReplies,
                    timestamp: message.timestamp
                )
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - User Message Bubble
private struct UserMessageBubble: View {
    let text: String
    let timestamp: Date

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(text)
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )

            Text(timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .padding(.trailing, 4)
        }
    }
}

// MARK: - AI Message Bubble
private struct AIMessageBubble: View {
    let japaneseTranslation: String
    let suggestedReplies: [SuggestedReply]
    let timestamp: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 意味（日本語訳）
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("意味")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.white.opacity(0.7))

                Text(japaneseTranslation)
                    .font(.callout)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.1))
            )

            // 3つの返答候補
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble")
                        .font(.caption)
                    Text("返し方の候補")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 4)

                ForEach(suggestedReplies) { reply in
                    SuggestedReplyCard(reply: reply)
                }
            }

            Text(timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 4)
        }
    }
}

// MARK: - Suggested Reply Card
private struct SuggestedReplyCard: View {
    let reply: SuggestedReply

    private var toneColor: Color {
        switch reply.tone {
        case .positive:
            return Color.green
        case .neutral:
            return Color.blue
        case .negative:
            return Color.orange
        }
    }

    private var toneLabel: String {
        switch reply.tone {
        case .positive:
            return "ポジティブ"
        case .neutral:
            return "ニュートラル"
        case .negative:
            return "ネガティブ"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // トーンラベル
            Text(toneLabel)
                .font(.caption2.weight(.semibold))
                .foregroundColor(toneColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(toneColor.opacity(0.2))
                )

            // 英語テキスト
            Text(reply.englishText)
                .font(.body.weight(.semibold))
                .foregroundColor(.cyan)

            // 日本語訳
            if !reply.japaneseTranslation.isEmpty {
                Text("→ \(reply.japaneseTranslation)")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.8))
            }

            // カタカナ読み
            if !reply.katakanaReading.isEmpty {
                Text(reply.katakanaReading)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            // 説明
            if !reply.explanation.isEmpty {
                Text(reply.explanation)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(toneColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
private struct RecordButton: View {
    var isRecording: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 28, weight: .bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(isRecording ? "字幕を停止" : "字幕を開始")
                        .font(.headline.weight(.bold))
                    Text(isRecording ? "タップして録音を終了" : "タップして録音を開始")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: isRecording
                        ? [Color.red.opacity(0.9), Color.red.opacity(0.7)]
                        : [Color.blue.opacity(0.9), Color.purple.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 12)
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "字幕を停止" : "字幕を開始")
        .animation(.easeInOut(duration: 0.2), value: isRecording)
    }
}

#Preview {
    ContentView()
}
