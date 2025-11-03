//
//  LiveTranscriber.swift
//  SpeakingAR
//
//  権限リクエストと音声セッション管理を改善したライブ文字起こしクラス
//

import AVFoundation
import Speech

@MainActor
final class LiveTranscriber: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var recordPermission: AVAudioSession.RecordPermission = .undetermined

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init(locale: Locale = Locale(identifier: Locale.preferredLanguages.first ?? "en-US")) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        recordPermission = AVAudioSession.sharedInstance().recordPermission
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

        do {
            try configureAudioSession()
            try beginRecognitionSession()
        } catch {
            stopTranscribing()
            transcript = "音声認識を開始できませんでした: \(error.localizedDescription)"
        }
    }

    func stopTranscribing() {
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
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if let error {
                Task { @MainActor in
                    self.stopTranscribing()
                    self.transcript = "音声認識中にエラーが発生しました: \(error.localizedDescription)"
                }
            } else if result?.isFinal == true {
                Task { @MainActor in
                    self.stopTranscribing()
                }
            }
        }
    }
}

