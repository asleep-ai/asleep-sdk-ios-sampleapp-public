//  ConfigView.swift - Copyright 2023 Asleep

import SwiftUI

struct ConfigView: View {

    @Binding var isTracking: Bool
    @Binding var userId: String
    var micPermissionGranted: Bool
    var isLoading: Bool
    var onViewReport: (() -> Void)?

    var body: some View  {
        HStack() {
            Text("Asleep SDK")
                .font(.title.bold())

            Spacer()

            if !isTracking, let onViewReport = onViewReport {
                Button("View Report") {
                    onViewReport()
                }
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isLoading ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isLoading)
            }
        }

        Divider()
            .padding(.vertical, 8)

        Spacer()

        HStack() {
            Text("User ID: \(userId)")
                .font(.caption.bold())
            Spacer()
        }

        // The SDK cannot record without this permission, so the sample keeps the current state on
        // screen instead of only reporting it once tracking fails.
        HStack() {
            Text("Microphone Permission: \(String(micPermissionGranted))")
                .font(.caption.bold())
            Spacer()
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(isTracking: .constant(false),
                   userId: .constant(""),
                   micPermissionGranted: true,
                   isLoading: false,
                   onViewReport: { print("View Report tapped") })
    }
}
