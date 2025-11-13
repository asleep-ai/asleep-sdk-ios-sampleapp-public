//  Color+SleepStages.swift - Copyright 2023 Asleep

import SwiftUI

extension Color {
    // Sleep Stage Colors
    static let sleepStageAwake = Color(red: 0.95, green: 0.43, blue: 0.55)      // #F26F8D
    static let sleepStageREM = Color(red: 0.58, green: 0.40, blue: 0.74)        // #9466BC
    static let sleepStageLight = Color(red: 0.40, green: 0.76, blue: 0.94)      // #66C2F0
    static let sleepStageDeep = Color(red: 0.26, green: 0.42, blue: 0.85)       // #426BD9

    // Snoring Colors
    static let snoringColor = Color(red: 0.95, green: 0.43, blue: 0.55)         // #F26F8D (pink)
    static let noSnoringColor = Color(red: 0.85, green: 0.85, blue: 0.85)       // #DADADA (gray)

    // Transparent color for spacing
    static let transparentStage = Color.clear
}
