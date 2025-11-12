//
//  ContentView.swift
//  SpeakingAR
//
//  Created by 水原樹 on 2025/11/03.
//

import ARKit
import RealityKit
import SwiftUI

struct ContentView: View {
    @StateObject private var transcriber = LiveTranscriber()

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer()
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color.black.opacity(0.45), Color.black.opacity(0.05), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                SubtitleView(
                    originalText: transcriber.transcript,
                    translatedText: transcriber.translatedTranscript,
                    translationInfo: transcriber.translationInfo,
                    translationError: transcriber.translationError,
                    isTranslating: transcriber.isTranslating,
                    aiResponse: transcriber.aiResponse,
                    aiError: transcriber.aiError,
                    isGeneratingAIResponse: transcriber.isGeneratingAIResponse,
                    japaneseTranslation: transcriber.japaneseTranslation,
                    englishReplyJapanese: transcriber.englishReplyJapanese,
                    katakanaReading: transcriber.katakanaReading
                )

                RecordButton(isRecording: transcriber.isRecording) {
                    if transcriber.isRecording {
                        transcriber.stopTranscribing(userInitiated: true)
                    } else {
                        transcriber.startTranscribing()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 44)
            .padding(.top, 24)
        }
        .onAppear {
            transcriber.requestPermissionsIfNeeded()
        }
    }
}

private struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        configureSession(for: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    private func configureSession(for arView: ARView) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)
    }
}
private struct SubtitleView: View {
    let originalText: String
    let translatedText: String
    let translationInfo: String?
    let translationError: String?
    let isTranslating: Bool
    let aiResponse: String
    let aiError: String?
    let isGeneratingAIResponse: Bool
    let japaneseTranslation: String
    let englishReplyJapanese: String  // ← 追加
    let katakanaReading: String

    private var trimmedAIResponse: String {
        aiResponse.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldShowTranslationSection: Bool {
        !originalText.isEmpty
    }

    private var shouldShowAISection: Bool {
        isGeneratingAIResponse || !trimmedAIResponse.isEmpty || !japaneseTranslation.isEmpty || !(aiError?.isEmpty ?? true)
    }

    var body: some View {
        VStack(spacing: 16) {
            statusHeader

            Divider()
                .opacity((shouldShowTranslationSection || shouldShowAISection) ? 1 : 0)

            ScrollView(showsIndicators: false) {
                content
                    .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var content: some View {
        if !shouldShowTranslationSection && !shouldShowAISection {
            Text("マイクボタンを押して英会話を開始")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                // 音声認識セクション
                if shouldShowTranslationSection {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(title: "あなた", systemImage: "person.fill")

                        Text(originalText)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        if !translatedText.isEmpty {
                            Divider()
                                .background(Color.white.opacity(0.2))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("英語に変換:")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(translatedText)
                                    .font(.callout)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }

                // AIセクション
                if shouldShowAISection {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader(title: "AIの提案", systemImage: "sparkles")

                        if isGeneratingAIResponse {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white.opacity(0.85))
                                Text("考え中…")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }

                        // 日本語訳（相手の発言の意味）
                        if !japaneseTranslation.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("意味:")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(japaneseTranslation)
                                    .font(.callout)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }

                        // 英語の返答
                        if !trimmedAIResponse.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("返し方:")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))

                                // 英語
                                Text(trimmedAIResponse)
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(Color.cyan)
                                    
                                // 日本語訳 ← 追加
                                if !englishReplyJapanese.isEmpty {
                                    Text("→ \(englishReplyJapanese)")
                                        .font(.callout)
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                        }

                        // カタカナ読み
                        if !katakanaReading.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("読み方:")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(katakanaReading)
                                    .font(.callout)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }

                        if let error = aiError, !error.isEmpty {
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.red.opacity(0.9))
                        }
                    }
                }
            }
        }
    }

    private var statusHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Label(
                isTranslating ? "リスニング中" : "待機中",
                systemImage: isTranslating ? "waveform" : "mic"
            )
            .font(.footnote.weight(.semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(isTranslating ? Color.green.opacity(0.25) : Color.blue.opacity(0.25))
            )
            .foregroundColor(.white.opacity(0.9))

            if let info = translationInfo, !info.isEmpty {
                ChipView(text: info, systemImage: "character.book.closed")
            }

            if let error = translationError, !error.isEmpty {
                ChipView(text: error, systemImage: "exclamationmark.triangle.fill", tint: .red.opacity(0.8))
            }

            Spacer(minLength: 0)
        }
    }

    private func sectionHeader(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.white.opacity(0.85))
    }
}

private struct ChipView: View {
    let text: String
    var systemImage: String
    var tint: Color = Color.white.opacity(0.85)

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption.weight(.medium))
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.6), lineWidth: 1)
        )
        .foregroundColor(tint)
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
