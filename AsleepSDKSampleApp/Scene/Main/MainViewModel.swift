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

        /// Base directory the SDK writes kept segments into, as
        /// `{recordingPath}/audio/{sessionId}/`. The very same URL has to be given to
        /// `createRecordingFileManager(recordingPath:)`, otherwise the lookup finds nothing.
        static let recordingPath: URL = {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return documents.appendingPathComponent("recordings")
        }()

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
            static let sessionAlreadyEnded = "Session Already Ended"

            // Error Messages - Detailed
            static let shouldResumeDetailed = "Sleep tracking should be resumed"
            static let over24HoursDetailed = "Sleep tracking cannot exceed 24 hours"
            static let audioInitFailedDetailed = "Another app is using the microphone, or there is an issue with the microphone settings."
            static let cannotActivateInBackgroundDetailed = "Cannot start sleep tracking while app is in background"
            static let unableODADetailed = "Unable to perform on-device analysis"
            static let odaIntegrityFailedDetailed = "On-device analysis integrity check failed"
            static let networkOfflineDetailed = "Please check your network connection."
            static let sessionAlreadyEndedDetailed = "The session has already ended."
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
            static let permissionAlertTitle = "Allow Access Permission"
            static let micPermissionDenied = "Microphone permission is required for sleep tracking. Please enable it in Settings."
            static let goToSettings = "Go to Settings"
            static let permissionAlertCancel = "Cancel"

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
        // Kept apart from `showError` so only this alert offers the Settings shortcut.
        @Published var showMicPermissionAlert = false
        @Published var errorMessage = ""
        @Published var errorLogs: [ErrorLog] = []
        @Published var isLoading = false

        // Current sleep data
        @Published var currentSleepStage: String?
        @Published var currentSnoringStage: String?

        // Audio route tracking
        @Published var currentAudioRoute: String?

        /// Which recordings to keep (v3.3.0). The plan is the ceiling - this only narrows it, it
        /// never turns on a kind the plan does not cover. Read when the tracking manager is created.
        @Published var recordingType: Asleep.RecordingType = .all

        // Microphone permission state shown on the main screen
        @Published private(set) var isMicPermissionGranted = false

        /// Reads the current microphone permission. The value can change outside the app (Settings),
        /// so the view refreshes it whenever the scene becomes active again.
        func refreshMicPermissionStatus() {
            isMicPermissionGranted = AVAudioSession.sharedInstance().recordPermission == .granted
        }

        // Computed property for backward compatibility
        var isTracking: Bool {
            trackingState == .tracking || trackingState == .interrupted
        }

        private var configContinuation: CheckedContinuation<Asleep.Config, Error>?

        /// Same set as the Android sample's `isWarning`: the session keeps running through these, so
        /// they belong in the warning log rather than in a blocking alert.
        private static let warningErrorCodes: [Asleep.AsleepErrorCode] = [
            .audioSilenced,
            .audioUnsilenced,
            .uploadFailed
        ]

        static func isWarning(_ error: Asleep.AsleepError) -> Bool {
            warningErrorCodes.contains(error.errorCode)
        }

        func clearErrors() {
            error = nil
            errorLogs = []
            showError = false
            showMicPermissionAlert = false
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
            // v3.3.0: setDebugLoggerDelegate(_:) is deprecated. setLogger(_:) delivers the same
            // messages with a level (d/i/w/e) and a typed tag.
            Asleep.setLogger(self)
        }

        func initSleepTrackingManager() {
            guard let config else { return }
            // v3.3.0 completable overload: an AsleepCompletableTrackingDelegate adds COMPLETE
            // polling (`didComplete(session:)`), and `recordingPath` is the on/off switch for the
            // audio files. `recordingType` is read here, so the manager is recreated whenever the
            // picker changed before a session starts.
            trackingManager = Asleep.createSleepTrackingManager(config: config,
                                                                delegate: self,
                                                                recordingPath: Self.recordingPath,
                                                                recordingType: recordingType)
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
                case .closeNotFound:
                    detailedMessage = Strings.sessionAlreadyEndedDetailed
                    shortMessage = Strings.sessionAlreadyEnded

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
                    /* A fatal error does not stop the SDK session by itself: without this call
                       the microphone stays on and a new startTracking() is rejected because the
                       session is still alive. Guarded by the state check so a failure from this
                       very stop call cannot recurse back here. */
                    if self.trackingState != .idle {
                        self.trackingManager?.stopTracking()
                    }
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

// MARK: - Extension for SDK Log (v3.3.0: AsleepLogger replaces AsleepDebugLoggerDelegate)
/// Every SDK log line arrives here with a level (`d`/`i`/`w`/`e`), a typed `tag` telling which
/// subsystem produced it, and the underlying `error` when there is one. The sample prints them to
/// the Xcode console - forward `msg` to your own logging stack instead if you keep one.
extension MainView.ViewModel: AsleepLogger {
    func d(tag: LogTag, msg: String, error: Error?) {
        print("[AsleepSDK][D][\(tag)] \(msg)\(error.map { " - \($0)" } ?? "")")
    }

    func e(tag: LogTag, msg: String, error: Error?) {
        print("[AsleepSDK][E][\(tag)] \(msg)\(error.map { " - \($0)" } ?? "")")
    }

    func i(tag: LogTag, msg: String, error: Error?) {
        print("[AsleepSDK][I][\(tag)] \(msg)\(error.map { " - \($0)" } ?? "")")
    }

    func w(tag: LogTag, msg: String, error: Error?) {
        print("[AsleepSDK][W][\(tag)] \(msg)\(error.map { " - \($0)" } ?? "")")
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
// v3.3.0: AsleepCompletableTrackingDelegate refines AsleepSleepTrackingManagerDelegate with
// `didCreate(sessionId:)` and `didComplete(session:)`. With a completable delegate the SDK calls
// `didCreate(sessionId:)` *instead of* `didCreate()`.
extension MainView.ViewModel: AsleepCompletableTrackingDelegate {
    func didFail(error: Asleep.AsleepError) {
        print("Failed tracking with the error: ", error)

        if Self.isWarning(error) {
            // Tracking survives these, so they go to the warning log instead of an alert that would
            // stop the session.
            let message = "\(error.errorCode.code) - \(error.errorCode.message ?? error.description)"
            Task { @MainActor in
                self.error = message
                self.errorLogs.append(MainView.ErrorLog(timestamp: Date(), message: message))
                self.isLoading = false
            }
        } else {
            handleError(error, title: Strings.sleepTrackingFailed, delegate: "AsleepSleepTrackingManagerDelegate.didFail", stopTracking: true, resetLoading: true)
        }
    }

    func didCreate(sessionId: String) {
        print("Session created:", sessionId)

        Task { @MainActor in
            self.sessionId = sessionId
            self.trackingState = .tracking
            self.error = nil
            self.errorLogs = []
            self.isLoading = false
        }
    }

    /// Arrives after `didClose(sessionId:)` once the server finished analysing the session. The
    /// kept audio files are written by then, so this is the point to look them up.
    func didComplete(session: Asleep.Model.Session) {
        print("Session completed:", session.id, "state:", session.state)

        logRecordingFiles(sessionId: session.id)
    }

    /// Reads the files back through a `RecordingFileManager` built on the same `recordingPath`
    /// that was given to `createSleepTrackingManager` - a different path always lists nothing.
    private func logRecordingFiles(sessionId: String) {
        let recordingFileManager = Asleep.createRecordingFileManager(recordingPath: Self.recordingPath)

        print("[Recording] Stored sessions:", recordingFileManager.getSessions())

        let snoringFiles = recordingFileManager.getSnoringFiles(sessionId: sessionId)
        let breathFiles = recordingFileManager.getBreathFiles(sessionId: sessionId)
        print("[Recording] \(sessionId) - snoring: \(snoringFiles.count), breath: \(breathFiles.count)")

        for file in recordingFileManager.getAllSegments(sessionId: sessionId) {
            print("[Recording] seq \(file.segmentIndex)",
                  "snoring: \(file.isSnoringDetected)",
                  "breath: \(file.isBreathDetected)",
                  "path: \(file.filePath?.lastPathComponent ?? "not kept")")
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
            self.refreshMicPermissionStatus()
            self.errorMessage = Strings.micPermissionDenied
            // Once denied, the system no longer prompts - the user has to flip the switch in
            // Settings, so the alert links there.
            self.showMicPermissionAlert = true
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
