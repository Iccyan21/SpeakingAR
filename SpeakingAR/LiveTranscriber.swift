//
//  LiveTranscriber.swift
//  SpeakingAR
//

import AVFoundation
import Speech

@MainActor
final class LiveTranscriber: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var recordPermission: AVAudioSession.RecordPermission = .undetermined

    // チャット履歴
    @Published var messages: [Message] = []

    // 一時的な状態（録音中の表示用）
    @Published var currentTranscript: String = ""
    @Published var isGeneratingAIResponse: Bool = false
    @Published var aiError: String?
    @Published var translatedTranscript: String = ""
    @Published var translationInfo: String?
    @Published var translationError: String?
    @Published var isTranslating: Bool = false

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let translator = SubtitleTranslator()
    private var translationTask: Task<Void, Never>?
    private var lastTranscribedText: String = ""
    private var nextTranslationRetryDate: Date?
    private var translationModelPreloadTask: Task<Void, Never>?

    private var shouldSuppressRecognitionTaskErrors: Bool = false

    private let aiResponder: AIResponder
    private var aiResponseTask: Task<Void, Never>?
    private var lastAIInput: String = ""

    init(locale: Locale = Locale(identifier: "en-US")) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        recordPermission = AVAudioSession.sharedInstance().recordPermission

        aiResponder = AIResponder()

        translationModelPreloadTask = Task { [translator] in
            #if canImport(Translation)
            await translator.preloadDefaultLanguagePairs()
            #endif
        }
    }

    @MainActor
    private func scheduleAIResponse(for text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            aiError = "AI 応答用のテキストが取得できませんでした。"
            isGeneratingAIResponse = false
            return
        }

        guard trimmed != lastAIInput else {
            currentTranscript = ""
            return
        }
        lastAIInput = trimmed

        aiResponseTask?.cancel()
        aiResponseTask = nil

        appendUserMessage(trimmed)
        currentTranscript = ""

        isGeneratingAIResponse = true
        aiError = nil

        aiResponseTask = Task {
            do {
                let responseData = try await aiResponder.generateResponse(for: trimmed)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.isGeneratingAIResponse = false
                    // AIメッセージを追加
                    let aiMessage = Message(
                        type: .ai(
                            japaneseTranslation: responseData.japaneseTranslation,
                            suggestedReplies: responseData.suggestedReplies.map { aiReply in
                                SuggestedReply(
                                    tone: ReplyTone(rawValue: aiReply.tone.rawValue) ?? .neutral,
                                    englishText: aiReply.englishText,
                                    japaneseTranslation: aiReply.japaneseTranslation,
                                    katakanaReading: aiReply.katakanaReading,
                                    explanation: aiReply.explanation
                                )
                            }
                        )
                    )
                    self.messages.append(aiMessage)

                    self.aiError = nil
                    self.aiResponseTask = nil
                }
            } catch is CancellationError {
                return
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "AI 応答の生成中にエラーが発生しました。"
                await MainActor.run {
                    self.isGeneratingAIResponse = false
                    self.aiError = message
                    self.aiResponseTask = nil
                }
            }
        }
    }

    func requestPermissionsIfNeeded() {
        if authorizationStatus == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    self?.authorizationStatus = status
                }
            }
        }

        let audioSession = AVAudioSession.sharedInstance()
        let currentPermission = audioSession.recordPermission

        if currentPermission == .undetermined {
            audioSession.requestRecordPermission { [weak self] granted in
                Task { @MainActor in
                    self?.recordPermission = granted ? .granted : .denied
                }
            }
        } else {
            recordPermission = currentPermission
        }
    }

    func startTranscribing() {
        guard !isRecording else { return }

        switch authorizationStatus {
        case .authorized:
            break
        case .notDetermined:
            requestPermissionsIfNeeded()
            fallthrough
        default:
            transcript = "音声認識の権限が許可されていません。設定アプリでマイクと音声認識の権限を有効にしてください。"
            return
        }

        guard recordPermission == .granted else {
            if recordPermission == .undetermined {
                requestPermissionsIfNeeded()
            }
            transcript = "マイクへのアクセスが許可されていません。設定アプリでマイク権限を有効にしてください。"
            return
        }

        prepareForNewSession()

        do {
            try configureAudioSession()
            try beginRecognitionSession()
        } catch {
            stopTranscribing()
            transcript = "音声認識を開始できませんでした: \(error.localizedDescription)"
        }
    }

    func stopTranscribing(userInitiated: Bool = false) {
        if userInitiated {
            shouldSuppressRecognitionTaskErrors = true
            let latestTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !latestTranscript.isEmpty {
                scheduleAIResponse(for: latestTranscript)
            }
        }
        translationTask?.cancel()
        translationTask = nil
        isTranslating = false
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        deactivateAudioSession()
    }

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func deactivateAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            #if DEBUG
            print("Failed to deactivate audio session: \(error.localizedDescription)")
            #endif
        }
    }

    private func beginRecognitionSession() throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            transcript = "音声認識サービスが現在利用できません。しばらくしてから再試行してください。"
            return
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let latestTranscript = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.transcript = latestTranscript
                    self.currentTranscript = latestTranscript
                }
            }

            if let error {
                Task { @MainActor in
                    if self.shouldSuppressRecognitionTaskErrors {
                        self.shouldSuppressRecognitionTaskErrors = false
                        return
                    }
                    self.stopTranscribing()
                    self.transcript = "音声認識中にエラーが発生しました: \(error.localizedDescription)"
                    self.aiError = "音声認識が停止したため、AI 応答を生成できません。"
                }
            } else if result?.isFinal == true {
                Task { @MainActor in
                    // 音声認識が完了したら、AI応答を生成
                    if !self.transcript.isEmpty {
                        self.scheduleAIResponse(for: self.transcript)
                    }
                    self.stopTranscribing()
                }
            }
        }
    }
    private func prepareForNewSession() {
        translationTask?.cancel()
        translationTask = nil
        translationModelPreloadTask?.cancel()
        translationModelPreloadTask = nil
        transcript = ""
        currentTranscript = ""
        translatedTranscript = ""
        translationInfo = nil
        translationError = nil
        isTranslating = false
        lastTranscribedText = ""
        nextTranslationRetryDate = nil
        shouldSuppressRecognitionTaskErrors = false
        aiResponseTask?.cancel()
        aiResponseTask = nil
        lastAIInput = ""
        isGeneratingAIResponse = false
        aiError = nil

        translationModelPreloadTask = Task { [translator] in
            #if canImport(Translation)
            await translator.preloadDefaultLanguagePairs()
            #endif
        }
    }

    @MainActor
    private func scheduleTranslation(for text: String) {
        guard text != lastTranscribedText else { return }
        lastTranscribedText = text

        translationTask?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            translatedTranscript = ""
            translationInfo = nil
            translationError = nil
            isTranslating = false
            translationTask = nil
            scheduleAIResponse(for: text)
            return
        }

        if let retryDate = nextTranslationRetryDate {
            if retryDate > Date() {
                isTranslating = false
                translatedTranscript = ""
                translationInfo = nil
                if translationError == nil {
                    translationError = "翻訳サービスを利用できません。ネットワーク接続と翻訳データを確認してください。"
                }
                translationTask = nil
                return
            } else {
                nextTranslationRetryDate = nil
            }
        }

        isTranslating = true
        translationError = nil
        if translatedTranscript.isEmpty {
            translationInfo = "翻訳モデルを準備中..."
        } else {
            translationInfo = nil
        }

        let translator = self.translator
        translationTask = Task {
            do {
                let outcome = try await translator.translate(trimmed)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.isTranslating = false
                    switch outcome {
                    case .translated(let result):
                        self.translatedTranscript = result.translatedText
                        self.translationInfo = self.localizedLanguagePairDescription(
                            sourceCode: result.sourceLanguageCode,
                            targetCode: result.targetLanguageCode
                        )
                        self.translationError = nil
                        self.nextTranslationRetryDate = nil
                    case .unsupportedLanguage(let code):
                        self.translatedTranscript = ""
                        self.translationInfo = code.map { self.unsupportedLanguageDescription(for: $0) }
                        self.translationError = "英語または日本語の音声のみ翻訳されます。"
                        self.nextTranslationRetryDate = nil
                    case .unavailable:
                        self.translatedTranscript = ""
                        self.translationInfo = nil
                        self.translationError = "翻訳サービスを利用できません。ネットワーク接続と翻訳データを確認してください。"
                        self.nextTranslationRetryDate = Date().addingTimeInterval(20)
                    }
                    self.translationTask = nil
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    self.isTranslating = false
                    self.translatedTranscript = ""
                    self.translationInfo = nil
                    self.translationError = "翻訳中にエラーが発生しました: \(error.localizedDescription)"
                    self.nextTranslationRetryDate = Date().addingTimeInterval(10)
                    self.translationTask = nil
                }
            }
        }
    }

    private func localizedLanguagePairDescription(sourceCode: String, targetCode: String) -> String {
        let sourceName = localizedLanguageName(for: sourceCode)
        let targetName = localizedLanguageName(for: targetCode)
        return "\(sourceName) → \(targetName)"
    }

    private func unsupportedLanguageDescription(for code: String) -> String {
        let languageName = localizedLanguageName(for: code)
        return "\(languageName) は翻訳対象外です"
    }

    private func localizedLanguageName(for code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code) ?? code
    }

    private func appendUserMessage(_ text: String) {
        let userMessage = Message(type: .user(text: text))
        messages.append(userMessage)
    }
}
