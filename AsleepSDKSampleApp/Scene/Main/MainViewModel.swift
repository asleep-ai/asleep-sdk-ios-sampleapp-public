//  SampleViewModel.swift - Copyright 2023 Asleep

import Foundation
import Combine
import AsleepSDK

extension MainView {
    final class ViewModel: ObservableObject {
        private(set) var trackingManager: Asleep.SleepTrackingManager?
        private(set) var reports: Asleep.Reports?
        
        @Published var userId: String?
        @Published var sessionId: String?
        @Published var sequenceNumber: Int?
        @Published var error: String?

        @Published var isTracking = false
        @Published var createdReport: Asleep.Model.Report?
        @Published private(set) var config: Asleep.Config?
        
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
            trackingManager?.startTracking()
        }
    }

    func didFailUserJoin(error: Asleep.AsleepError) {
        print("Failed user join with the error:", error)
    }

    func userDidDelete(userId: String) {
        print("Deleted user id:", userId)
    }
}

// MARK: - Extension for Managing the Sleep Measurement Start to Finish Process
extension MainView.ViewModel: AsleepSleepTrackingManagerDelegate {
    func didFail(error: Asleep.AsleepError) {
        switch error {
        case let .httpStatus(code, _, message) where code == 403 || code == 404:
            Task { @MainActor in
                self.isTracking = false
                self.error = String("\(code): \(message ?? "")")
            }
            print("Stopped sleep tracking with the error: ", error)
        default:
            print("Failed tracking with the error: ", error)
        }
    }

    func didCreate() {
        Task { @MainActor in
            self.isTracking = true
            self.error = nil
        }
    }

    func didUpload(sequence: Int) {
        Task { @MainActor in
            self.sequenceNumber = sequence
        }
    }

    func didClose(sessionId: String) {
        Task { @MainActor in
            self.isTracking = false
            self.sessionId = sessionId
        }
    }

    func analysing(session: Asleep.Model.Session) {
        print("Analysis result:", session)
    }

    func didInterrupt() {
        print("Tracking is interrupted")
    }

    func didResume() {
        print("Tracking is resumed")
    }

    func micPermissionWasDenied() {
        Task { @MainActor in
            self.isTracking = false
        }
        print(micPermissionWasDenied)
    }
}
