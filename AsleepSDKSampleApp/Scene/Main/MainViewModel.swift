//  SampleViewModel.swift - Copyright 2023 Asleep

import Foundation
import Combine
import AVFoundation
import AsleepSDK

extension MainView {
    struct ErrorLog: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
    }

    final class ViewModel: ObservableObject {
        // MARK: - Tracking State
        enum TrackingState {
            case idle
            case tracking
            case interrupted
        }

        // MARK: - Constants
        static let minTrackingMinutes = 5

        static var insufficientTimeAlertMessage: String {
            String(format: Strings.insufficientTimeMessage, minTrackingMinutes)
        }

        enum Strings {
            // Sleep Stage
            static let checkableAfterSequence = "Checkable if sequence is 10+"
            static let awake = "Awake"
            static let lightSleep = "Light Sleep"
            static let deepSleep = "Deep Sleep"
            static let remSleep = "REM Sleep"
            static let unknownStage = "Unknown"

            // Snoring
            static let snoring = "Snoring"
            static let notSnoring = "Not Snoring"

            // Error Titles
            static let userRegistrationFailed = "User Registration Failed"
            static let sleepTrackingFailed = "Sleep Tracking Failed"

            // Error Messages - Short
            static let shouldResume = "Should Resume"
            static let over24Hours = "Over 24 hours"
            static let audioInitFailed = "Audio Init Failed"
            static let cannotActivateInBackground = "Cannot Activate in Background"
            static let unableODA = "Unable ODA"
            static let odaIntegrityFailed = "ODA Integrity Failed"
            static let networkOffline = "Network Offline"
            static let configurationError = "Configuration Error"

            // Error Messages - Detailed
            static let shouldResumeDetailed = "Sleep tracking should be resumed"
            static let over24HoursDetailed = "Sleep tracking cannot exceed 24 hours"
            static let audioInitFailedDetailed = "Failed to initialize audio recording"
            static let cannotActivateInBackgroundDetailed = "Cannot start sleep tracking while app is in background"
            static let unableODADetailed = "Unable to perform on-device analysis"
            static let odaIntegrityFailedDetailed = "On-device analysis integrity check failed"
            static let networkOfflineDetailed = "No network connection. Please check your internet connection."
            static let configurationErrorDetailed = "Configuration error:\nPlease check your API settings"
            static let unknownError = "Unknown error"
            static let unknownErrorOccurred = "Unknown error occurred:"
            static let noDetailsAvailable = "No details available"

            // Network Error Templates
            static let startTrackingNetworkFail = "Failed to start tracking - Network error"
            static let stopTrackingNetworkFail = "Failed to stop tracking - Network error"
            static let startTrackingNetworkFailShort = "Start Tracking Network Fail: "
            static let stopTrackingNetworkFailShort = "Stop Tracking Network Fail: "
            static let apiResponseError = "API response error from:"
            static let responseErrorPrefix = "Response Error: "
            static let unknownPrefix = "Unknown: "
            static let httpStatusPrefix = "HTTP Status: "

            // Permission
            static let micPermissionDenied = "[AsleepSleepTrackingManagerDelegate.micPermissionWasDenied] Permission Required:\nMicrophone permission denied. Please enable it in Settings > Privacy > Microphone."

            // Insufficient Time Alert
            static let insufficientTimeTitle = "Invalid report provided"
            static let insufficientTimeMessage = "You need to track for at least %d minutes to receive a sleep report. Do you want to exit without a report?"
            static let insufficientTimeExit = "Exit"
            static let insufficientTimeCancel = "Cancel"
        }

        private enum SleepStage: Int {
            case awake = 0
            case lightSleep = 1
            case deepSleep = 2
            case remSleep = 3

            var displayName: String {
                switch self {
                case .awake: return Strings.awake
                case .lightSleep: return Strings.lightSleep
                case .deepSleep: return Strings.deepSleep
                case .remSleep: return Strings.remSleep
                }
            }
        }

        private enum SnoringStatus: Int {
            case notSnoring = 0
            case snoring = 1

            var displayName: String {
                switch self {
                case .snoring: return Strings.snoring
                case .notSnoring: return Strings.notSnoring
                }
            }
        }

        private(set) var trackingManager: Asleep.SleepTrackingManager?
        private(set) var reports: Asleep.Reports?

        @Published var userId: String?
        @Published var sessionId: String?
        @Published var sequenceNumber: Int?
        @Published var error: String?

        @Published var trackingState: TrackingState = .idle
        @Published var createdReport: Asleep.Model.Report?
        @Published var createdReportList: [Asleep.Model.SleepSession]?
        @Published private(set) var config: Asleep.Config?

        @Published var showError = false
        @Published var errorMessage = ""
        @Published var errorLogs: [ErrorLog] = []
        @Published var isLoading = false

        // Current sleep data
        @Published var currentSleepStage: String?
        @Published var currentSnoringStage: String?

        // Audio route tracking
        @Published var currentAudioRoute: String?

        // Computed property for backward compatibility
        var isTracking: Bool {
            trackingState == .tracking || trackingState == .interrupted
        }

        private var configContinuation: CheckedContinuation<Asleep.Config, Error>?

        func clearErrors() {
            error = nil
            errorLogs = []
            showError = false
            errorMessage = ""
        }

        func initAsleepConfig(apiKey: String,
                              userId: String,
                              baseUrl: URL?,
                              callbackUrl: URL?) {
            Asleep.initAsleepConfig(apiKey: apiKey,
                                    userId: userId.isEmpty ? nil : userId,
                                    baseUrl: baseUrl,
                                    callbackUrl: callbackUrl,
                                    delegate: self)
            Asleep.setDebugLoggerDelegate(self)
        }

        func initSleepTrackingManager() {
            guard let config else { return }
            trackingManager = Asleep.createSleepTrackingManager(config: config,
                                                                delegate: self)
        }

        func initReport() {
            guard let config else { return }
            reports = Asleep.createReports(config: config)
        }

        func ensureConfig(apiKey: String, userId: String, baseUrl: URL?, callbackUrl: URL?) async throws -> Asleep.Config {
            if let config = self.config {
                return config
            }

            return try await withCheckedThrowingContinuation { continuation in
                self.configContinuation = continuation
                self.initAsleepConfig(
                    apiKey: apiKey,
                    userId: userId,
                    baseUrl: baseUrl,
                    callbackUrl: callbackUrl
                )
            }
        }

        private func handleError(_ error: Asleep.AsleepError, title: String = "Error", delegate: String = "", stopTracking: Bool = true, resetLoading: Bool = true) {
            print("handleError called with error: \(error), title: \(title)")
            Task { @MainActor in
                var detailedMessage = ""
                var shortMessage = ""

                switch error {
                case .shouldResume:
                    detailedMessage = Strings.shouldResumeDetailed
                    shortMessage = Strings.shouldResume
                case .over24hours:
                    detailedMessage = Strings.over24HoursDetailed
                    shortMessage = Strings.over24Hours
                case .audioInitializationFailed:
                    detailedMessage = Strings.audioInitFailedDetailed
                    shortMessage = Strings.audioInitFailed
                case .cannotActivateInBackground:
                    detailedMessage = Strings.cannotActivateInBackgroundDetailed
                    shortMessage = Strings.cannotActivateInBackground
                case .unableODA:
                    detailedMessage = Strings.unableODADetailed
                    shortMessage = Strings.unableODA
                case .ODAIntegrityFail:
                    detailedMessage = Strings.odaIntegrityFailedDetailed
                    shortMessage = Strings.odaIntegrityFailed
                case .startTrackingNetworkFail(let code, let msg):
                    detailedMessage = "\(Strings.startTrackingNetworkFail) \(code):\n\(msg ?? Strings.unknownError)"
                    shortMessage = "\(Strings.startTrackingNetworkFailShort)\(code)"
                case .stopTrackingNetworkFail(let code, let msg):
                    detailedMessage = "\(Strings.stopTrackingNetworkFail) \(code):\n\(msg ?? Strings.unknownError)"
                    shortMessage = "\(Strings.stopTrackingNetworkFailShort)\(code)"
                case .networkOffline:
                    detailedMessage = Strings.networkOfflineDetailed
                    shortMessage = Strings.networkOffline
                case .httpStatus(let code, let errorCode, let detail):
                    detailedMessage = "\(Strings.httpStatusPrefix)\(code)\n\(errorCode ?? 0)\n\(detail ?? Strings.noDetailsAvailable)"
                    shortMessage = "\(code): \(detail ?? "")"
                case .responseResult(let endpoint):
                    detailedMessage = "\(Strings.apiResponseError)\n\(endpoint)"
                    shortMessage = "\(Strings.responseErrorPrefix)\(endpoint)"
                case .unknown(let systemError):
                    detailedMessage = "\(Strings.unknownErrorOccurred)\n\(systemError.localizedDescription)"
                    shortMessage = "\(Strings.unknownPrefix)\(systemError.localizedDescription)"
                case .configurationError:
                    detailedMessage = Strings.configurationErrorDetailed
                    shortMessage = Strings.configurationError

                // v3.1.7+: Handles new error types using error.description
                // Note: Will be finalized in v3.2.0 - descriptions may change
                // Add specific cases above if custom handling is needed
                default:
                    detailedMessage = "\(Strings.unknownErrorOccurred)\n\(error.description)"
                    shortMessage = "\(Strings.unknownPrefix)\(error.description)"
                }

                self.error = shortMessage

                let delegateInfo = delegate.isEmpty ? "" : "[\(delegate)] "
                self.errorMessage = "\(delegateInfo)\(title):\n\(detailedMessage)"
                self.showError = true

                if stopTracking {
                    self.trackingState = .idle
                }

                if resetLoading {
                    self.isLoading = false
                }

                print("Setting showError to true, errorMessage: \(self.errorMessage)")
            }
        }
    }
}

// MARK: - Extension for SDK Debug Log
extension MainView.ViewModel: AsleepDebugLoggerDelegate {
    func didPrint(message: String) {
    }
}

// MARK: - Extension for User ID Creation and Deletion
extension MainView.ViewModel: AsleepConfigDelegate {
    func userDidJoin(userId: String, config: Asleep.Config) {
        Task { @MainActor in
            self.config = config
            self.userId = userId
            initSleepTrackingManager()
            initReport()

            if let continuation = configContinuation {
                continuation.resume(returning: config)
                configContinuation = nil
                // Don't start tracking when called from View Report
            } else {
                // Basic usage
                trackingManager?.startTracking()

                // Example: Start tracking with additional audio session options (v3.1.7+)
                // trackingManager?.startTracking(additionalAudioSessionOptions: [.duckOthers])
            }
        }
    }

    func didFailUserJoin(error: Asleep.AsleepError) {
        print("Failed user join with the error:", error)

        configContinuation?.resume(throwing: error)
        configContinuation = nil

        handleError(error, title: Strings.userRegistrationFailed, delegate: "AsleepConfigDelegate.didFailUserJoin")
    }

    func userDidDelete(userId: String) {
        print("Deleted user id:", userId)
    }
}

// MARK: - Extension for Managing the Sleep Measurement Start to Finish Process
extension MainView.ViewModel: AsleepSleepTrackingManagerDelegate {
    func didFail(error: Asleep.AsleepError) {
        print("Failed tracking with the error: ", error)

        if case let .unknown(systemError) = error {
            Task { @MainActor in
                self.error = "\(Strings.unknownPrefix)\(systemError.localizedDescription)"
                self.errorLogs.append(MainView.ErrorLog(
                    timestamp: Date(),
                    message: "\(Strings.unknownPrefix)\(systemError.localizedDescription)"
                ))
                self.isLoading = false
            }
        } else {
            handleError(error, title: Strings.sleepTrackingFailed, delegate: "AsleepSleepTrackingManagerDelegate.didFail", stopTracking: true, resetLoading: true)
        }
    }

    func didCreate() {
        Task { @MainActor in
            self.trackingState = .tracking
            self.error = nil
            self.errorLogs = []
            self.isLoading = false
        }
    }

    func didUpload(sequence: Int) {
        Task { @MainActor in
            self.sequenceNumber = sequence
            // Request latest analysis data every upload
            self.trackingManager?.requestAnalysis()
        }
    }

    func didClose(sessionId: String) {
        Task { @MainActor in
            self.trackingState = .idle
            self.sessionId = sessionId
            self.isLoading = false
            // Clear current sleep data when tracking stops
            self.currentSleepStage = nil
            self.currentSnoringStage = nil
        }
    }

    func analysing(session: Asleep.Model.Session) {
        print("Analysis result:", session)

        Task { @MainActor in
            // Get the most recent sleep stage
            if let sleepStages = session.sleepStages,
               let latestStage = sleepStages.last {
                self.currentSleepStage = convertSleepStageToString(latestStage)
            } else {
                self.currentSleepStage = Strings.checkableAfterSequence
            }

            // Get the most recent snoring stage
            if let snoringStages = session.snoringStages,
               let latestSnoring = snoringStages.last,
               let snoringStatus = SnoringStatus(rawValue: latestSnoring) {
                self.currentSnoringStage = "\(latestSnoring) (\(snoringStatus.displayName))"
            } else {
                self.currentSnoringStage = nil
            }
        }
    }

    private func convertSleepStageToString(_ stage: Int) -> String {
        let stageName: String
        if let sleepStage = SleepStage(rawValue: stage) {
            stageName = sleepStage.displayName
        } else {
            stageName = Strings.unknownStage
        }
        return "\(stage) (\(stageName))"
    }

    func didInterrupt() {
        print("Tracking is interrupted")
        Task { @MainActor in
            self.trackingState = .interrupted
            // Keep all data (startTime, sequenceNumber, sleep stages) intact
            // User can still stop tracking from interrupted state
        }
    }

    func didResume() {
        print("Tracking is resumed")
        Task { @MainActor in
            self.trackingState = .tracking
            // All data remains intact, tracking continues from where it was interrupted
        }
    }

    func micPermissionWasDenied() {
        Task { @MainActor in
            self.trackingState = .idle
            self.isLoading = false
            self.errorMessage = Strings.micPermissionDenied
            self.showError = true
        }
        print("Microphone permission was denied")
    }

    // MARK: - Audio Route Change Delegates (v3.1.7+)

    func willChangeAudioRoute(from oldRoute: AVAudioSessionRouteDescription,
                              to newRoute: AVAudioSessionRouteDescription) {
        let oldOutput = oldRoute.outputs.first?.portType.rawValue ?? "unknown"
        let newOutput = newRoute.outputs.first?.portType.rawValue ?? "unknown"

        print("[Audio Route] Will change: \(oldOutput) -> \(newOutput)")

        // You can add custom logic here before the route changes
        // Example: Pause audio playback if needed
        // if audioPlayer?.isPlaying == true {
        //     audioPlayer?.pause()
        // }
    }

    func didChangeAudioRoute(to newRoute: AVAudioSessionRouteDescription) {
        let output = newRoute.outputs.first?.portType.rawValue ?? "unknown"

        print("[Audio Route] Did change to: \(output)")

        Task { @MainActor in
            self.currentAudioRoute = output
        }

        // You can add custom logic here after the route changes
        // Example: Resume audio playback if needed
        // audioPlayer?.play()
    }
}
