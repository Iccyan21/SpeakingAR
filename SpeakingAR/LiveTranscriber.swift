//
//  LiveTranscriber.swift
//  SpeakingAR
//

import AVFoundation
import NaturalLanguage
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

    @Published var aiResponseEnglish: String = ""
    @Published var aiResponseJapanese: String = ""
    @Published var aiError: String?
    @Published var isGeneratingAIResponse: Bool = false

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let languageRecognizer = NLLanguageRecognizer()
    private var guidanceTask: Task<Void, Never>?
    private var lastProcessedTranscript: String = ""

    private let translator = SubtitleTranslator()
    private let aiResponder: AIResponder?
    private let aiSetupErrorMessage: String?
    private var isCancellingRecognition = false

    init(locale: Locale = Locale(identifier: Locale.preferredLanguages.first ?? "en-US")) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        recordPermission = AVAudioSession.sharedInstance().recordPermission

        var responder: AIResponder?
        var setupError: String?
        do {
            responder = try AIResponder()
        } catch {
            setupError = (error as? LocalizedError)?.errorDescription ?? "The AI assistant could not be initialized."
        }
        aiResponder = responder
        aiSetupErrorMessage = setupError
        if let setupError {
            aiError = setupError
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
            transcript = "Speech recognition permission has not been granted. Enable microphone and speech recognition in Settings."
            return
        }

        guard recordPermission == .granted else {
            if recordPermission == .undetermined {
                requestPermissionsIfNeeded()
            }
            transcript = "Microphone access has not been granted. Enable the microphone permission in Settings."
            return
        }

        prepareForNewSession()

        do {
            try configureAudioSession()
            try beginRecognitionSession()
        } catch {
            stopTranscribing()
            transcript = "Could not start speech recognition: \(error.localizedDescription)"
        }
    }

    func stopTranscribing(cancelGuidance: Bool = true) {
        if cancelGuidance {
            guidanceTask?.cancel()
            guidanceTask = nil
            isTranslating = false
            isGeneratingAIResponse = false
        }
        isCancellingRecognition = recognitionTask != nil
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
            transcript = "Speech recognition is currently unavailable. Please try again later."
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
                    self.handleTranscriptUpdate(for: latestTranscript, isFinal: result.isFinal)
                }
            }

            if let error {
                let nsError = error as NSError
                if nsError.domain == SFSpeechRecognizerErrorDomain,
                   nsError.code == SFSpeechRecognitionErrorCode.canceled.rawValue,
                   self.isCancellingRecognition {
                    self.isCancellingRecognition = false
                    return
                }

                Task { @MainActor in
                    self.stopTranscribing()
                    self.transcript = "A speech recognition error occurred: \(error.localizedDescription)"
                    self.aiError = "AI suggestions are unavailable because speech recognition stopped."
                }
            }
        }
    }
    private func prepareForNewSession() {
        guidanceTask?.cancel()
        guidanceTask = nil
        transcript = ""
        translatedTranscript = ""
        translationInfo = nil
        translationError = nil
        isTranslating = false
        lastProcessedTranscript = ""
        aiResponseEnglish = ""
        aiResponseJapanese = ""
        isGeneratingAIResponse = false
        aiError = aiResponder == nil ? aiSetupErrorMessage : nil
        isCancellingRecognition = false
    }

    @MainActor
    private func handleTranscriptUpdate(for text: String, isFinal: Bool) {
        if isFinal {
            requestGuidance(for: text)
        }
    }

    @MainActor
    private func requestGuidance(for text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != lastProcessedTranscript else { return }
        lastProcessedTranscript = trimmed

        guidanceTask?.cancel()

        guard !trimmed.isEmpty else {
            translatedTranscript = ""
            translationInfo = nil
            translationError = nil
            aiResponseEnglish = ""
            aiResponseJapanese = ""
            aiError = aiResponder == nil ? aiSetupErrorMessage : nil
            isTranslating = false
            isGeneratingAIResponse = false
            guidanceTask = nil
            return
        }

        languageRecognizer.reset()
        languageRecognizer.processString(trimmed)
        let detectedCode = languageRecognizer.dominantLanguage?.rawValue

        guard detectedCode == "en" else {
            translatedTranscript = ""
            translationInfo = nil
            translationError = "Speak in English to see the Japanese translation."
            aiResponseEnglish = ""
            aiResponseJapanese = ""
            aiError = "Speak in English to receive AI suggestions."
            isTranslating = false
            isGeneratingAIResponse = false
            guidanceTask = nil
            return
        }

        translatedTranscript = ""
        translationInfo = "English → Japanese"
        translationError = nil
        isTranslating = true

        aiResponseEnglish = ""
        aiResponseJapanese = ""
        let responder = aiResponder
        if responder != nil {
            isGeneratingAIResponse = true
            aiError = nil
        } else {
            isGeneratingAIResponse = false
            aiError = aiSetupErrorMessage
        }

        guidanceTask = Task { [weak self] in
            guard let self else { return }

            await self.performTranslation(for: trimmed)
            if Task.isCancelled { return }
            await self.performAI(for: trimmed, responder: responder)
            await MainActor.run {
                self.guidanceTask = nil
            }
        }
    }
}

extension LiveTranscriber {
    private func performTranslation(for text: String) async {
        do {
            let outcome = try await translator.translate(text)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                switch outcome {
                case .translated(let result):
                    let trimmed = result.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.translatedTranscript = trimmed
                    self.translationInfo = "English → Japanese"
                    if trimmed.isEmpty {
                        self.translationError = "The translation was empty."
                        self.isTranslating = self.aiResponder != nil
                    } else {
                        self.translationError = nil
                        self.isTranslating = false
                    }
                case .unsupportedLanguage:
                    self.translatedTranscript = ""
                    self.translationError = "The translation service could not process this utterance."
                    self.isTranslating = self.aiResponder != nil
                case .unavailable:
                    self.translatedTranscript = ""
                    if self.aiResponder == nil {
                        self.translationError = "Translation is unavailable on this device. Set the OPENAI_API_KEY environment variable to enable AI translation."
                        self.isTranslating = false
                    } else {
                        self.isTranslating = true
                    }
                }
            }
        } catch is CancellationError {
            return
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "The translation request failed."
            await MainActor.run {
                self.translatedTranscript = ""
                if self.aiResponder == nil {
                    self.translationError = "\(message) Set the OPENAI_API_KEY environment variable to enable AI translation."
                } else {
                    self.translationError = message
                }
                self.isTranslating = self.aiResponder != nil
            }
        }
    }

    private func performAI(for text: String, responder: AIResponder?) async {
        guard let responder else {
            await MainActor.run {
                self.isGeneratingAIResponse = false
            }
            return
        }

        do {
            let output = try await responder.generateGuidance(for: text)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.isGeneratingAIResponse = false
                let trimmedReplyEn = output.replyEn.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedReplyJa = output.replyJa.trimmingCharacters(in: .whitespacesAndNewlines)
                self.aiResponseEnglish = trimmedReplyEn
                self.aiResponseJapanese = trimmedReplyJa
                if trimmedReplyEn.isEmpty && trimmedReplyJa.isEmpty {
                    self.aiError = "The AI did not provide a suggestion."
                } else {
                    self.aiError = nil
                }

                let trimmedTranslation = output.userTranslationJa.trimmingCharacters(in: .whitespacesAndNewlines)
                if self.translatedTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   !trimmedTranslation.isEmpty {
                    self.translatedTranscript = trimmedTranslation
                    self.translationInfo = "English → Japanese"
                    self.translationError = nil
                } else if self.translatedTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          trimmedTranslation.isEmpty,
                          self.translationError == nil {
                    self.translationError = "The AI did not return a translation."
                }
                if self.isTranslating {
                    self.isTranslating = false
                }
            }
        } catch is CancellationError {
            return
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "The AI request failed."
            await MainActor.run {
                self.isGeneratingAIResponse = false
                self.aiResponseEnglish = ""
                self.aiResponseJapanese = ""
                self.aiError = message
                if self.translatedTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   self.translationError == nil {
                    self.translationError = message
                }
                self.isTranslating = false
            }
        }
    }
}

