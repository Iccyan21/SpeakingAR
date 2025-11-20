//
//  ContentView.swift
//  SpeakingAR
//
//  Created by 水原樹 on 2025/11/03.
//

import SwiftUI

struct ContentView: View {
    private enum Tab {
        case chat
        case guide
    }

    @State private var selectedTab: Tab = .chat

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatExperienceView()
                .tag(Tab.chat)
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                }

            WordMannerCatalogView()
                .tag(Tab.guide)
                .tabItem {
                    Label("Word", systemImage: "book.closed.fill")
                }
        }
    }
}

struct ChatExperienceView: View {
    @StateObject private var transcriber = LiveTranscriber()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isProUser") private var isProUser = false

    @State private var showOnboarding = false
    @State private var showTutorialSheet = false
    @State private var showSubscriptionSheet = false
    @State private var showLearningPlanSheet = false

    @State private var hasSeenDailyCoach = false

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
            case .ai(_, _, _):
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

                SessionGuidanceView(
                    isRecording: transcriber.isRecording,
                    hasMessages: !transcriber.messages.isEmpty,
                    streakCount: weeklyStreak,
                    onOpenTutorial: { showTutorialSheet = true }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

                DailyGoalProgressCard(
                    goalMinutes: dailyGoalMinutes,
                    practicedMinutes: practicedMinutesToday,
                    streakCount: weeklyStreak,
                    onOpenPlan: { showLearningPlanSheet = true },
                    onDismissCoach: { hasSeenDailyCoach = true }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
                .opacity(hasSeenDailyCoach ? 0.65 : 1)


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
    @State private var showMicroAction = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text("マイクボタンを押して\n英会話を開始")
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showMicroAction.toggle()
                }
            } label: {
                Label("録音の流れを確認", systemImage: "lightbulb")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)

            if showMicroAction {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "1.circle.fill")
                        Text("マイクをタップして、相手の声を数秒聞き取ります")
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "2.circle.fill")
                        Text("字幕が出たら、AI の返答例を声に出して真似します")
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "3.circle.fill")
                        Text("良かった返しをそのまま会話に使いましょう")
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))
                .padding(12)
                .frame(maxWidth: 320)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
            }
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

            case .ai(let japaneseTranslation, let suggestedReplies, let isStreamingReplies):
                Spacer(minLength: 50)
                AIMessageBubble(
                    japaneseTranslation: japaneseTranslation,
                    suggestedReplies: suggestedReplies,
                    isStreamingReplies: isStreamingReplies,
                    timestamp: message.timestamp
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
    let isStreamingReplies: Bool
    let timestamp: Date

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

            if suggestedReplies.isEmpty {
                if isStreamingReplies {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white.opacity(0.7))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("返し方を準備中…")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                            Text("翻訳を先に表示しています。続いて3つの返答例が届きます。")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption)
                            Text("返し方の候補は生成されませんでした")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.yellow.opacity(0.8))

                        Text("翻訳の確信度が低いため、提案を控えています。もう一度録音するか、ネットワーク状態を確認してください。")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            } else {
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

// MARK: - Session Guidance
private struct SessionGuidanceView: View {
    let isRecording: Bool
    let hasMessages: Bool
    let streakCount: Int
    var onOpenTutorial: () -> Void

    private var guidanceTitle: String {
        if isRecording {
            return "今の発話を聞いています"
        }
        if hasMessages {
            return "次の一言を声に出してみましょう"
        }
        return "マイクを押して、相手の声をキャッチ"
    }

    private var guidanceMessage: String {
        if isRecording {
            return "姿勢を楽にして、相手の話を自然に待ちましょう。聞き取りが終わるとすぐ字幕が表示されます。"
        }
        if hasMessages {
            return "AI が提示した例文の中から 1 つ選んで、ゆっくりでも声に出すと会話の定着が早くなります。"
        }
        return "最初の 10 秒だけ聞き取れば OK。小さな成功を積み上げましょう。"
    }

    private var streakNote: String {
        streakCount >= 5 ? "連続 \(streakCount) 日。よく続いています！" : "今日が \(streakCount) 日目。まずは 3 日連続を目指しましょう。"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: isRecording ? "waveform" : "sparkle.magnifyingglass")
                    .font(.title3)
                    .foregroundColor(.cyan)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(guidanceTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(guidanceMessage)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                }
            }

            HStack {
                Label(streakNote, systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.orange.opacity(0.9))

                Spacer()

                Button(action: onOpenTutorial) {
                    Text("使い方を確認")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.14, green: 0.19, blue: 0.36), Color(red: 0.08, green: 0.1, blue: 0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Daily Goal Progress
private struct DailyGoalProgressCard: View {
    let goalMinutes: Double
    let practicedMinutes: Double
    let streakCount: Int
    var onOpenPlan: () -> Void
    var onDismissCoach: () -> Void

    private var progress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(practicedMinutes / goalMinutes, 1)
    }

    private var progressHeadline: String {
        if progress >= 1 {
            return "今日の目標達成！"
        } else if progress >= 0.5 {
            return "あと少しで折り返し"
        } else {
            return "最初の一歩を積み上げましょう"
        }
    }

    private var progressDetail: String {
        if progress >= 1 {
            return "\(Int(practicedMinutes)) 分の練習を完了。好きなフレーズを繰り返して定着させましょう。"
        }
        return "目標 \(Int(goalMinutes)) 分のうち \(Int(practicedMinutes)) 分完了。短いセッションでも効果があります。"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progressHeadline)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(progressDetail)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button(action: onDismissCoach) {
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.7))
                        .padding(6)
                        .background(Color.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .tint(.cyan)
                HStack {
                    Label("目標 \(Int(goalMinutes)) 分", systemImage: "target")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Label("連続 \(streakCount) 日", systemImage: "calendar")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Button(action: onOpenPlan) {
                Text("Learning Plan を調整")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
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
