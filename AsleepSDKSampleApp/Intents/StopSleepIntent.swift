//  StopSleepIntent.swift - Copyright 2024 Asleep

import AppIntents

@available(iOS 16, *)
struct StopSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Sleep"
    static var description = IntentDescription("Stop Sleep Tracking")

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .stopSleep, object: nil)
        return .result()
    }
}

extension Notification.Name {
    static let stopSleep = Notification.Name("stopSleep")
}
