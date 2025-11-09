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

            VStack(spacing: 16) {

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
                    englishReplyJapanese: transcriber.englishReplyJapanese,// ← 追加
                    katakanaReading: transcriber.katakanaReading          // ← 追加
                    
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
            .padding(.vertical, 40)
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
        content
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: Capsule())
            .shadow(radius: 10)
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
            VStack(alignment: .leading, spacing: 12) {
                // 音声認識セクション
                if shouldShowTranslationSection {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "waveform")
                            Text("あなた")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.85))
                        
                        Text(originalText)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                    }
                }

                // AIセクション
                if shouldShowAISection {
                    if shouldShowTranslationSection {
                        Divider()
                            .background(Color.white.opacity(0.3))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("AIの提案")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.85))

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
                                    .foregroundColor(.cyan)
                                
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
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
private struct RecordButton: View {
    var isRecording: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                Text(isRecording ? "停止" : "録音")
            }
            .font(.title2.weight(.bold))
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(isRecording ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(radius: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "字幕を停止" : "字幕を開始")
    }
}

#Preview {
    ContentView()
}
