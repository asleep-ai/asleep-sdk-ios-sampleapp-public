//  StartSleepIntent.swift - Copyright 2024 Asleep

import AppIntents

@available(iOS 16, *)
struct StartSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sleep"
    static var description = IntentDescription("Start Sleep Tracking")

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .startSleep, object: nil)
        return .result()
    }
}

extension Notification.Name {
    static let startSleep = Notification.Name("startSleep")
}
