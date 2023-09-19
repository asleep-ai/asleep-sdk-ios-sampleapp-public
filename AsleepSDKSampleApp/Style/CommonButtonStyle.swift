//  CommonButtonStyle.swift - Copyright 2023 Asleep

import SwiftUI

struct CommonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(4)
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
