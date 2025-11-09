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

    @Published var translatedTranscript: String = ""
    @Published var translationInfo: String?
    @Published var translationError: String?
    @Published var isTranslating: Bool = false

    @Published var aiResponse: String = ""
    @Published var aiError: String?
    @Published var isGeneratingAIResponse: Bool = false

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let translator = SubtitleTranslator()
    private var translationTask: Task<Void, Never>?
    private var lastTranscribedText: String = ""
    private var isTranslationAvailable: Bool = true

    private let aiResponder: AIResponder?
    private let aiSetupErrorMessage: String?
    private var aiResponseTask: Task<Void, Never>?
    private var lastAIInput: String = ""

    init(locale: Locale = Locale(identifier: Locale.preferredLanguages.first ?? "en-US")) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        recordPermission = AVAudioSession.sharedInstance().recordPermission

        var responder: AIResponder?
        var setupError: String?
        do {
            responder = try AIResponder()
        } catch {
            setupError = (error as? LocalizedError)?.errorDescription ?? "AI 応答機能を初期化できませんでした。"
        }
        aiResponder = responder
        aiSetupErrorMessage = setupError
        if let setupError {
            aiError = setupError
        }
    }

    @MainActor
    private func scheduleAIResponse(for text: String) {
        guard text != lastAIInput else { return }
        lastAIInput = text

        aiResponseTask?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            aiResponse = ""
            aiError = aiSetupErrorMessage
            isGeneratingAIResponse = false
            aiResponseTask = nil
            return
        }

        guard let responder = aiResponder else {
            aiResponse = ""
            aiError = aiSetupErrorMessage
            isGeneratingAIResponse = false
            aiResponseTask = nil
            return
        }

        isGeneratingAIResponse = true
        aiError = nil

        aiResponseTask = Task {
            do {
                let reply = try await responder.generateResponse(for: trimmed)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.isGeneratingAIResponse = false
                    self.aiResponse = reply
                    self.aiError = reply.isEmpty ? "AI からの返答が取得できませんでした。" : nil
                    self.aiResponseTask = nil
                }
            } catch is CancellationError {
                return
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "AI 応答の生成中にエラーが発生しました。"
                await MainActor.run {
                    self.isGeneratingAIResponse = false
                    self.aiResponse = ""
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

    func stopTranscribing() {
        translationTask?.cancel()
        translationTask = nil
        aiResponseTask?.cancel()
        aiResponseTask = nil
        isTranslating = false
        isGeneratingAIResponse = false
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
                    self.scheduleTranslation(for: latestTranscript)
                    self.scheduleAIResponse(for: latestTranscript)

                }
            }

            if let error {
                Task { @MainActor in
                    self.stopTranscribing()
                    self.transcript = "音声認識中にエラーが発生しました: \(error.localizedDescription)"
                    self.aiError = "音声認識が停止したため、AI 応答を生成できません。"
                }
            } else if result?.isFinal == true {
                Task { @MainActor in
                    self.stopTranscribing()
                }
            }
        }
    }
    private func prepareForNewSession() {
        translationTask?.cancel()
        translationTask = nil
        transcript = ""
        translatedTranscript = ""
        translationInfo = nil
        translationError = nil
        isTranslating = false
        lastTranscribedText = ""
        isTranslationAvailable = true
        aiResponse = ""
        aiResponseTask?.cancel()
        aiResponseTask = nil
        lastAIInput = ""
        isGeneratingAIResponse = false
        aiError = aiSetupErrorMessage
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

        guard isTranslationAvailable else {
            isTranslating = false
            translatedTranscript = ""
            translationInfo = nil
            if translationError == nil {
                translationError = "翻訳サービスを利用できません。ネットワーク接続と翻訳データを確認してください。"
            }
            translationTask = nil
            return
        }

        isTranslating = true
        translationError = nil
        translationInfo = nil

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
                        self.translationInfo = self.localizedLanguagePairDescription(sourceCode: result.sourceLanguageCode, targetCode: result.targetLanguageCode)
                        self.translationError = nil
                    case .unsupportedLanguage(let code):
                        self.translatedTranscript = ""
                        self.translationInfo = code.map { self.unsupportedLanguageDescription(for: $0) }
                        self.translationError = "英語または日本語の音声のみ翻訳されます。"
                    case .unavailable:
                        self.translatedTranscript = ""
                        self.translationInfo = nil
                        self.translationError = "翻訳サービスを利用できません。ネットワーク接続と翻訳データを確認してください。"
                        self.isTranslationAvailable = false
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
}

