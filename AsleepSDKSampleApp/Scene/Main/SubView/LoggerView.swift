//  LoggerView.swift - Copyright 2023 Asleep

import SwiftUI

struct LoggerView: View {

    // MARK: - Constants
    private let uploadIntervalMinutes: Double = 0.5  // 30 seconds

    @Binding var error: String?
    @Binding var isTracking: Bool
    @Binding var startTime: Date?
    @Binding var sessionId: String?
    @Binding var sequenceNumber: Int?
    @Binding var errorLogs: [MainView.ErrorLog]
    @Binding var currentSleepStage: String?
    @Binding var currentSnoringStage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isTracking {
                showTrackingView()
            } else {
                showDoneView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func showTrackingView() -> some View {
        Text("Tracking Sleep...")
            .font(.title)
            .frame(maxWidth: .infinity)

        VStack(alignment: .leading) {
            Text("Start Time : \(startTime?.fullDateString ?? "")")

            if let sequenceNumber = sequenceNumber {
                Text(String(format: "Uploaded Sequence : \(sequenceNumber) (%.1f min.)", uploadIntervalMinutes * Double(sequenceNumber + 1)))
            } else {
                Text("Uploaded Sequence : - (0.0 min.)")
            }

            if let sleepStage = currentSleepStage {
                Text("Current Sleep Stage : \(sleepStage)")
                    .padding(.top, 8)
            }

            if let snoringStage = currentSnoringStage {
                Text("Current Snoring Stage : \(snoringStage)")
            }
        }
        Text("Upload every 30 seconds.")
            .foregroundColor(.gray)

        Text("To obtain a valid report, you must track for at least 5 minutes (10+ uploads).")
            .foregroundColor(.gray)

        // Show error logs in scrollable list
        if !errorLogs.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text("⚠️ Errors (Not Critical, Warning Level)")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(errorLogs) { errorLog in
                            HStack(alignment: .top, spacing: 4) {
                                Text(errorLog.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Text(errorLog.message)
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .frame(maxHeight: 160)
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func showDoneView() -> some View {
        if !(sessionId ?? "").isEmpty {
            Text("Tracking Done!")
                .font(.title)
                .frame(maxWidth: .infinity)
            Text("Session ID: \(sessionId ?? "")")
        } else if let error = error {
            Text("Tracking Terminated")
                .font(.title)
                .frame(maxWidth: .infinity)
            Text(error)
        }
    }
}

struct LoggerView_Previews: PreviewProvider {
    static var previews: some View {
        LoggerView(error: .constant(nil),
                   isTracking: .constant(true),
                   startTime: .constant(Date()),
                   sessionId: .constant(""),
                   sequenceNumber: .constant(0),
                   errorLogs: .constant([]),
                   currentSleepStage: .constant("1 (Light Sleep)"),
                   currentSnoringStage: .constant("0 (Not Snoring)"))
    }
}
