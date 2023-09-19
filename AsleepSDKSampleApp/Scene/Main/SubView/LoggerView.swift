//  LoggerView.swift - Copyright 2023 Asleep

import SwiftUI

struct LoggerView: View {
    
    @Binding var isTracking: Bool
    @Binding var startTime: Date?
    @Binding var sessionId: String?
    @Binding var sequenceNumber: Int?
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            if isTracking {
                showTrackingView()
            } else {
                showDoneView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
        .border(.gray)
    }

    @ViewBuilder
    private func showTrackingView() -> some View {
        Group {
            Text("Tracking Sleep...")
                .font(.title)

            VStack() {
                Text("Start Time : \(startTime?.dateString ?? "")")

                if let sequenceNumber = sequenceNumber {
                    Text(String(format: "Uploaded Sequence : \(sequenceNumber) (%.1f min.)", 0.5 * Double(sequenceNumber + 1)))
                } else {
                    Text("Uploaded Sequence : - (0.0 min.)")
                }
            }
            
            Text("Upload every 30 seconds.")
                .foregroundColor(.gray)

            VStack() {
                Text("To obtain the valid report,")
                Text("you must upload 40 or more times")
            }
            .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    private func showDoneView() -> some View {
        Group {
            if !(sessionId ?? "").isEmpty {
                Text("Tracking Done!")
                    .font(.title)
                Text("Session ID: \(sessionId ?? "")")
            }
        }
    }
}

struct LoggerView_Previews: PreviewProvider {
    static var previews: some View {
        LoggerView(isTracking: .constant(true),
                   startTime: .constant(Date()),
                   sessionId: .constant(""),
                   sequenceNumber: .constant(0))
    }
}
