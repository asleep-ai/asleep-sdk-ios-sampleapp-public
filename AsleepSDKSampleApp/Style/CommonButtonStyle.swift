//  CommonButtonStyle.swift - Copyright 2023 Asleep

import SwiftUI

struct CommonButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .foregroundColor(.white)
            .background(isEnabled ? Color.blue : Color.gray)
            .cornerRadius(4)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct ContentView: View {
    var body: some View {
        Button("Press Me") {
            print("Button pressed!")
        }
        .buttonStyle(CommonButtonStyle())
    }
}
