//
//  ContentView.swift
//  SpeakingAR
//
//  Created by 水原樹 on 2025/11/03.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var transcriber = LiveTranscriber()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isProUser") private var isProUser = false

    @State private var showOnboarding = false
    @State private var showTutorialSheet = false
    @State private var showSubscriptionSheet = false
    @State private var showLearningPlanSheet = false

    @State private var hasDismissedLimitedNotice = false
    @State private var hasDismissedProBanner = false

    @State private var dailyGoalMinutes: Double = 15
    @State private var practicedMinutesToday: Double = 6
    @State private var weeklyStreak = 4

    /// nil の場合は無料利用の回数制限を無効化
    private let freeTierLimit: Int? = nil

    private var aiResponseCount: Int {
        transcriber.messages.reduce(0) { partialResult, message in
            switch message.type {
            case .ai:
                return partialResult + 1
            case .user:
                return partialResult
            }
        }
    }

    private var remainingFreeResponses: Int? {
        guard let freeTierLimit else { return nil }
        return max(freeTierLimit - aiResponseCount, 0)
    }

    private var isRecordingLocked: Bool {
        guard let freeTierLimit else { return false }
        return !isProUser && aiResponseCount >= freeTierLimit
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ChatHeader(
                    isRecording: transcriber.isRecording,
                    remainingFreeResponses: remainingFreeResponses,
                    freeTierLimit: freeTierLimit,
                    isProUser: isProUser,
                    onShowTutorial: { showTutorialSheet = true },
                    onShowSubscription: { showSubscriptionSheet = true }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                PracticeFocusPanel(
                    practicedMinutes: practicedMinutesToday,
                    goalMinutes: dailyGoalMinutes,
                    streakCount: weeklyStreak,
                    onAdjustGoal: { showLearningPlanSheet = true }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                if !isProUser,
                   let limit = freeTierLimit,
                   let remaining = remainingFreeResponses,
                   !hasDismissedLimitedNotice {
                    LimitedAccessNoticeView(
                        remainingResponses: remaining,
                        limit: limit,
                        onUpgrade: { showSubscriptionSheet = true },
                        onDismiss: { hasDismissedLimitedNotice = true }
                    )
                    .padding(.horizontal, 16)
                }

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

                            if transcriber.isRecording && !transcriber.currentTranscript.isEmpty {
                                MessageRow(
                                    message: Message(
                                        type: .user(text: transcriber.currentTranscript)
                                    )
                                )
                                .opacity(0.6)
                            }

                            if transcriber.isGeneratingAIResponse,
                               !transcriber.messages.contains(where: { $0.isProvisional }) {
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
                        if isRecordingLocked {
                            showSubscriptionSheet = true
                        }
                    }
                }

                if !isProUser && !hasDismissedProBanner {
                    ProFeatureBanner(
                        onUpgrade: { showSubscriptionSheet = true },
                        onDismiss: { hasDismissedProBanner = true }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }

                RecordButton(
                    isRecording: transcriber.isRecording,
                    isLocked: isRecordingLocked
                ) {
                    if transcriber.isRecording {
                        transcriber.stopTranscribing(userInitiated: true)
                        return
                    }

                    if isRecordingLocked {
                        showSubscriptionSheet = true
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
        .sheet(isPresented: $showTutorialSheet) {
            TutorialSheetView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showLearningPlanSheet) {
            LearningPlanSheet(
                dailyGoalMinutes: $dailyGoalMinutes,
                practicedMinutes: $practicedMinutesToday,
                streakCount: $weeklyStreak
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionSheetView(
                isProUser: $isProUser,
                remainingResponses: remainingFreeResponses,
                limit: freeTierLimit
            )
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingExperienceView {
                hasCompletedOnboarding = true
                showOnboarding = false
            }
        }
        .onAppear {
            transcriber.requestPermissionsIfNeeded()
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
    }
}

// MARK: - Chat Header
private struct ChatHeader: View {
    let isRecording: Bool
    let remainingFreeResponses: Int?
    let freeTierLimit: Int?
    let isProUser: Bool
    var onShowTutorial: () -> Void
    var onShowSubscription: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("English Chat")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Circle()
                        .fill(isRecording ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)

                    Text(isRecording ? "リスニング中" : "待機中")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    if !isProUser,
                       let remainingFreeResponses,
                       let freeTierLimit {
                        Text("残り \(remainingFreeResponses) / \(freeTierLimit)")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                            )
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("SpeakingAR Pro")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                            )
                            .foregroundColor(.white)
                    }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: onShowTutorial) {
                    Label("チュートリアル", systemImage: "questionmark.circle")
                        .labelStyle(.iconOnly)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)

                Button(action: onShowSubscription) {
                    Label("アップグレード", systemImage: isProUser ? "crown.fill" : "lock.fill")
                        .labelStyle(.iconOnly)
                        .foregroundColor(isProUser ? .yellow : .white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
            }
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
                UserMessageBubble(text: text, timestamp: message.timestamp)
                Spacer(minLength: 50)

            case .ai(let japaneseTranslation, let suggestedReplies):
                Spacer(minLength: 50)
                AIMessageBubble(
                    japaneseTranslation: japaneseTranslation,
                    suggestedReplies: suggestedReplies,
                    timestamp: message.timestamp,
                    isProvisional: message.isProvisional
                )
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
    let isProvisional: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            if isProvisional {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white.opacity(0.7))
                        .scaleEffect(0.8)

                    Text("AI プレビューを表示中…")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
            }

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
            Text(toneLabel)
                .font(.caption2.weight(.semibold))
                .foregroundColor(toneColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(toneColor.opacity(0.2))
                )

            Text(reply.englishText)
                .font(.body.weight(.semibold))
                .foregroundColor(.cyan)

            if !reply.japaneseTranslation.isEmpty {
                Text("→ \(reply.japaneseTranslation)")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.8))
            }

            if !reply.katakanaReading.isEmpty {
                Text(reply.katakanaReading)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

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
    var isLocked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isRecording ? "stop.circle.fill" : (isLocked ? "lock.fill" : "mic.circle.fill"))
                    .font(.system(size: 28, weight: .bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(isRecording ? "字幕を停止" : (isLocked ? "Proを解放" : "字幕を開始"))
                        .font(.headline.weight(.bold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(backgroundGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 12)
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "字幕を停止" : "字幕を開始")
        .animation(.easeInOut(duration: 0.2), value: isRecording)
        .animation(.easeInOut(duration: 0.2), value: isLocked)
    }

    private var subtitle: String {
        if isRecording {
            return "タップして録音を終了"
        } else if isLocked {
            return "無制限で使うにはアップグレード"
        } else {
            return "タップして録音を開始"
        }
    }

    private var backgroundGradient: LinearGradient {
        if isRecording {
            return LinearGradient(
                colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if isLocked {
            return LinearGradient(
                colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

private struct PracticeFocusPanel: View {
    var practicedMinutes: Double
    var goalMinutes: Double
    var streakCount: Int
    var onAdjustGoal: () -> Void

    private var progress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(practicedMinutes / goalMinutes, 1)
    }

    private var remainingMinutes: Int {
        max(Int(goalMinutes - min(practicedMinutes, goalMinutes)), 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(practicedMinutes)) / \(Int(goalMinutes)) 分 完了")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                    Text("目標まであと \(remainingMinutes) 分")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Button(action: onAdjustGoal) {
                    Text("計画を調整")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            ProgressView(value: progress) {
                EmptyView()
            }
            .progressViewStyle(.linear)
            .tint(.cyan)

            HStack {
                Label("連続 \(streakCount) 日", systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.orange)

                Spacer()

                Label("次のご褒美: \(remainingMinutes) 分", systemImage: "gift.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct LimitedAccessNoticeView: View {
    let remainingResponses: Int
    let limit: Int
    var onUpgrade: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .font(.headline)
                    .foregroundColor(.yellow)
                Text("無料プランの残り回数")
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: onDismiss) {
                    Text("❌")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            ProgressView(value: Double(limit - remainingResponses), total: Double(limit)) {
                EmptyView()
            }
            .progressViewStyle(.linear)
            .tint(.yellow)

            Text("AI の返答を \(limit) 回まで体験できます。残り \(remainingResponses) 回です。")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Button(action: onUpgrade) {
                Text("Pro で無制限にする")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.2), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}

private struct ProFeatureBanner: View {
    var onUpgrade: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Text("❌")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 4) {
                    Text("SpeakingAR Pro を体験")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("リアルタイム訳と会話テンプレを無制限で利用できます")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button(action: onUpgrade) {
                    Text("詳しく")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}

private struct TutorialSheetView: View {
    private struct TutorialItem: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let systemImage: String
        let accent: Color
    }

    private let items: [TutorialItem] = [
        .init(title: "字幕を開始", message: "マイクボタンを押すとリアルタイムで相手の英語を字幕化します。", systemImage: "mic.circle.fill", accent: .cyan),
        .init(title: "AI の提案を活用", message: "AI が返答候補を3トーンで用意。気に入ったものをタップして練習しましょう。", systemImage: "text.bubble.fill", accent: .purple),
        .init(title: "復習モード", message: "Learning Plan で1日の目標を設定し、スキマ時間でも英会話を続けましょう。", systemImage: "calendar", accent: .green)
    ]

    var body: some View {
        NavigationStack {
            List(items) { item in
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: item.systemImage)
                        .font(.title2)
                        .foregroundColor(item.accent)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("クイックチュートリアル")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct LearningPlanSheet: View {
    @Binding var dailyGoalMinutes: Double
    @Binding var practicedMinutes: Double
    @Binding var streakCount: Int

    @State private var tempGoal: Double = 15
    @State private var tempPractice: Double = 6
    @State private var tempStreak: Int = 1

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("1日の目標")) {
                    Slider(value: $tempGoal, in: 5...60, step: 5) {
                        Text("目標")
                    }
                    Text("\(Int(tempGoal)) 分")
                        .font(.headline)
                }

                Section(header: Text("今日の進捗")) {
                    Slider(value: $tempPractice, in: 0...tempGoal, step: 1) {
                        Text("練習済み")
                    }
                    Text("\(Int(tempPractice)) 分 完了")
                        .font(.headline)
                }

                Section(header: Text("連続日数")) {
                    Stepper(value: $tempStreak, in: 1...365) {
                        Text("\(tempStreak) 日")
                    }
                }
            }
            .navigationTitle("Learning Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        dailyGoalMinutes = tempGoal
                        practicedMinutes = min(tempPractice, tempGoal)
                        streakCount = tempStreak
                    }
                }
            }
        }
        .onAppear {
            tempGoal = dailyGoalMinutes
            tempPractice = practicedMinutes
            tempStreak = streakCount
        }
    }
}

private struct SubscriptionSheetView: View {
    @Binding var isProUser: Bool
    let remainingResponses: Int?
    let limit: Int?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(isProUser ? "Pro プラン有効" : "SpeakingAR Pro")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(isProUser ? "引き続き無制限で利用できます" : "AI の返答を無制限に、字幕も高速化")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    featureRow(icon: "bolt.fill", text: "リアルタイム字幕の高速モード")
                    featureRow(icon: "quote.bubble.fill", text: "返答候補を無制限に保存")
                    featureRow(icon: "lock.open.fill", text: "チュートリアルパックの開放")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                if !isProUser,
                   let remainingResponses,
                   let limit {
                    Text("無料プランの残り: \(remainingResponses) / \(limit)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Button(action: toggleSubscription) {
                    Text(isProUser ? "Pro を終了" : "¥600 / 月でアップグレード")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProUser ? Color.red.opacity(0.2) : Color.blue)
                        .foregroundColor(isProUser ? .red : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()
            .navigationTitle("アップグレード")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
                .font(.body)
        }
    }

    private func toggleSubscription() {
        isProUser.toggle()
    }
}

private struct OnboardingExperienceView: View {
    var onFinish: () -> Void
    @State private var selection = 0

    private let pages: [(title: String, message: String, icon: String)] = [
        ("話す勇気をつくる", "英語の相手の発言をリアルタイムで字幕化し、意味をすぐ把握。", "ear.badge.waveform"),
        ("AI コーチと練習", "状況に合わせた3つの返答候補で、すぐに会話へ。", "sparkles"),
        ("学習習慣を維持", "Learning Plan と Pro プランで毎日の進捗を管理。", "calendar")
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.02, blue: 0.08), Color(red: 0.07, green: 0.06, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer(minLength: 20)

                TabView(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 20) {
                            Image(systemName: page.icon)
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                            Text(page.title)
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                            Text(page.message)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(maxHeight: 360)

                Button(action: onFinish) {
                    Text(selection == pages.count - 1 ? "会話を始める" : "スキップ")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 32)
                }

                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
