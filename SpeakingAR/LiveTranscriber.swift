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

    private let aiResponder: AIResponder?
    private let aiSetupErrorMessage: String?

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
                Task { @MainActor in
                    self.stopTranscribing()
                    self.transcript = "A speech recognition error occurred: \(error.localizedDescription)"
                    self.aiError = "AI suggestions are unavailable because speech recognition stopped."
                }
            } else if result?.isFinal == true {
                Task { @MainActor in
                    self.stopTranscribing(cancelGuidance: false)
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
        aiError = aiSetupErrorMessage
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
            aiError = aiSetupErrorMessage
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

        guard let responder = aiResponder else {
            translatedTranscript = ""
            translationInfo = "English → Japanese"
            translationError = aiSetupErrorMessage
            aiResponseEnglish = ""
            aiResponseJapanese = ""
            aiError = aiSetupErrorMessage
            isTranslating = false
            isGeneratingAIResponse = false
            guidanceTask = nil
            return
        }

        isTranslating = true
        translationError = nil
        translationInfo = "English → Japanese"
        isGeneratingAIResponse = true
        aiError = nil

        guidanceTask = Task {
            do {
                let output = try await responder.generateGuidance(for: trimmed)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.isTranslating = false
                    self.isGeneratingAIResponse = false
                    self.translatedTranscript = output.userTranslationJa.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.translationInfo = "English → Japanese"
                    self.translationError = self.translatedTranscript.isEmpty ? "The AI did not return a translation." : nil
                    self.aiResponseEnglish = output.replyEn.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.aiResponseJapanese = output.replyJa.trimmingCharacters(in: .whitespacesAndNewlines)
                    if self.aiResponseEnglish.isEmpty && self.aiResponseJapanese.isEmpty {
                        self.aiError = "The AI did not provide a suggestion."
                    } else {
                        self.aiError = nil
                    }
                    self.guidanceTask = nil
                }
            } catch is CancellationError {
                return
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "The AI request failed."
                await MainActor.run {
                    self.isTranslating = false
                    self.isGeneratingAIResponse = false
                    self.translatedTranscript = ""
                    self.translationInfo = "English → Japanese"
                    self.translationError = message
                    self.aiResponseEnglish = ""
                    self.aiResponseJapanese = ""
                    self.aiError = message
                    self.guidanceTask = nil
                }
            }
        }
    }
}

