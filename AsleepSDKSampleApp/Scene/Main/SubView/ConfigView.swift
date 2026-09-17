//  ConfigView.swift - Copyright 2023 Asleep

import SwiftUI
import AsleepSDK

// v3.3.0: the picker binds the SDK enum itself. Labels match the Android sample app.
extension Asleep.RecordingType {
    static let pickerOptions: [Asleep.RecordingType] = [.all, .snoringOnly, .breathOnly]

    var displayName: String {
        switch self {
        case .all: return "ALL"
        case .snoringOnly: return "SNORING_ONLY"
        case .breathOnly: return "BREATH_ONLY"
        @unknown default: return "UNKNOWN"
        }
    }
}

struct ConfigView: View {

    @Binding var isTracking: Bool
    @Binding var userId: String
    @Binding var recordingType: Asleep.RecordingType
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

        // Which recordings to keep out of what the plan allows. Read when the tracking manager is
        // created, so it is locked while a session is running.
        HStack() {
            Text("Recording Type:")
                .font(.caption.bold())

            Picker("", selection: $recordingType) {
                ForEach(Asleep.RecordingType.pickerOptions, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)
            .disabled(isTracking)

            Spacer()
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(isTracking: .constant(false),
                   userId: .constant(""),
                   recordingType: .constant(.all),
                   micPermissionGranted: true,
                   isLoading: false,
                   onViewReport: { print("View Report tapped") })
    }
}
