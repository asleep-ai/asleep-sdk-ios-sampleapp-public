//  ReportView.swift - Copyright 2023 Asleep

import SwiftUI
import AsleepSDK

struct ReportView: View {
    @Environment(\.presentationMode) private var presentationMode
    let reports: Asleep.Reports?
    let sessionList: [Asleep.Model.SleepSession]

    @State private var currentIndex: Int = 0
    @State private var currentReport: Asleep.Model.Report?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var currentSession: Asleep.Model.SleepSession? {
        guard !sessionList.isEmpty, currentIndex >= 0, currentIndex < sessionList.count else { return nil }
        return sessionList[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                }
                .padding(20)
            }

            if let session = currentSession {
                // Date navigation
                HStack(spacing: 16) {
                    Button(action: showOlderReport) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                    .disabled(currentIndex >= sessionList.count - 1 || isLoading)

                    Spacer()

                    Text(getSessionDate(session))
                        .font(.headline)

                    Spacer()

                    Button(action: showNewerReport) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                    }
                    .disabled(currentIndex <= 0 || isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Report content
                if isLoading {
                    Spacer()
                    ProgressView("Loading report...")
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Failed to load report")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else if let report = currentReport {
                    ScrollView {
                        detailView(report: report)
                            .padding(.horizontal, 16)
                    }
                    .background(Color(.systemGray6))
                } else {
                    Spacer()
                    Text("No report available")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                Spacer()
                Text("No session available")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .onAppear {
            fetchCurrentReport()
        }
    }

    @ViewBuilder
    func detailView(report: Asleep.Model.Report) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Session ID
            Text(report.session.id)
                .font(.title3.bold())
                .textSelection(.enabled)

            // Basic info
            VStack(alignment: .leading, spacing: 4) {
                Text("Time Range: \(report.session.startTime.fullDateString) ~ \(report.session.endTime?.fullDateString ?? "N/A")")
                Text("Unexpected End Time: \(report.session.unexpectedEndTime?.description ?? "N/A")")
                Text("Session State: \(report.session.state.rawValue)")
                Text("Missing Data Ratio: \(String(format: "%.1f%%", report.missingDataRatio * 100))")
                Text("Peculiarities: \(report.peculiarities.description)")
            }
            .font(.system(size: 14))
            .textSelection(.enabled)

            Divider()

            // Sleep Stages Section
            sleepStagesSection(report: report)

            Divider()

            // Snoring Stages Section
            snoringStagesSection(report: report)
        }
        .padding(.vertical, 16)
    }

    @ViewBuilder
    func sleepStagesSection(report: Asleep.Model.Report) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Stages")
                .font(.headline)

            if let sleepStages = report.session.sleepStages {
                // Create slices for each stage
                let awakeSlices = makeSlice(
                    stages: sleepStages,
                    targetValue: 0,
                    mainColor: .sleepStageAwake,
                    otherColor: .transparentStage
                )
                let remSlices = makeSlice(
                    stages: sleepStages,
                    targetValue: 3,
                    mainColor: .sleepStageREM,
                    otherColor: .transparentStage
                )
                let lightSlices = makeSlice(
                    stages: sleepStages,
                    targetValue: 1,
                    mainColor: .sleepStageLight,
                    otherColor: .transparentStage
                )
                let deepSlices = makeSlice(
                    stages: sleepStages,
                    targetValue: 2,
                    mainColor: .sleepStageDeep,
                    otherColor: .transparentStage
                )

                SleepStagesView(
                    awakeSlices: awakeSlices,
                    remSlices: remSlices,
                    lightSlices: lightSlices,
                    deepSlices: deepSlices,
                    startTime: getTimeOnly(report.session.startTime),
                    endTime: report.session.endTime.map { getTimeOnly($0) } ?? "N/A"
                )
                .padding(.vertical, 8)

                // Sleep statistics
                //  - Uncomment as needed to check results
//                if let stat = report.stat {
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Sleep Efficiency: \(stat.sleepEfficiency?.description ?? "N/A")")
//                        Text("Sleep Latency: \(stat.sleepLatency?.description ?? "N/A") min")
//                        Text("Wakeup Latency: \(stat.wakeupLatency?.description ?? "N/A") min")
//                        Text("Sleep Time: \(stat.sleepTime?.description ?? "N/A") min")
//                        Text("Wake Time: \(stat.wakeTime?.description ?? "N/A") min")
//                        Text("Time in REM: \(stat.timeInRem?.description ?? "N/A") min (\(formatPercentage(stat.remRatio)))")
//                        Text("Time in Light: \(stat.timeInLight?.description ?? "N/A") min (\(formatPercentage(stat.lightRatio)))")
//                        Text("Time in Deep: \(stat.timeInDeep?.description ?? "N/A") min (\(formatPercentage(stat.deepRatio)))")
//                        Text("Time in Wake: \(stat.timeInWake?.description ?? "N/A") min (\(formatPercentage(stat.wakeRatio)))")
//                    }
//                    .font(.system(size: 13))
//                    .foregroundColor(.secondary)
//                    .textSelection(.enabled)
//                }
            } else {
                Text("No sleep stages data")
                    .foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder
    func snoringStagesSection(report: Asleep.Model.Report) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Snoring Stages")
                .font(.headline)

            if let snoringStages = report.session.snoringStages {
                let snoringSlices = makeSlice(
                    stages: snoringStages,
                    targetValue: 1,
                    mainColor: .snoringColor,
                    otherColor: .noSnoringColor
                )

                StackedBarView(slices: snoringSlices, height: 32)
                    .cornerRadius(4)
                    .padding(.vertical, 8)

                // Snoring statistics
                //  - Uncomment as needed to check results
                if let stat = report.stat {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Snoring Ratio: \(formatPercentage(stat.snoringRatio))")
//                        Text("Time in Snoring: \(stat.timeInSnoring?.description ?? "N/A") min")
//                        Text("Time in No Snoring: \(stat.timeInNoSnoring?.description ?? "N/A") min")
//                        Text("Snoring Count: \(stat.snoringCount?.description ?? "N/A")")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                } else {
                    Text("Snoring ratio cannot be checked")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            } else {
                Text("No snoring stages data")
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Helper Functions

    func fetchCurrentReport() {
        guard let session = currentSession else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let reports = reports else {
                    throw NSError(domain: "ReportView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Reports manager is not initialized"])
                }

                let report = try await reports.report(sessionId: session.sessionId)

                await MainActor.run {
                    currentReport = report
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    func showOlderReport() {
        if currentIndex < sessionList.count - 1 {
            currentIndex += 1
            fetchCurrentReport()
        }
    }

    func showNewerReport() {
        if currentIndex > 0 {
            currentIndex -= 1
            fetchCurrentReport()
        }
    }

    func getSessionDate(_ session: Asleep.Model.SleepSession) -> String {
        guard let endTime = session.sessionEndTime else {
            return session.sessionStartTime.simpleDateString
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: endTime)
    }

    func getTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func formatPercentage(_ value: Float?) -> String {
        guard let value = value else { return "N/A" }
        return String(format: "%.1f%%", value * 100)
    }
}
