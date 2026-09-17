//  ReportView.swift - Copyright 2023 Asleep

import SwiftUI
import AVFoundation
import AsleepSDK

/// Plays one kept segment at a time. Tapping the row that is already playing stops it, and so does
/// reaching the end of the file or leaving the report sheet.
final class RecordingPlayer: NSObject, ObservableObject {
    @Published private(set) var playingURL: URL?

    private var player: AVAudioPlayer?

    func toggle(_ url: URL) {
        if playingURL == url {
            stop()
            return
        }

        stop()

        do {
            // Tracking leaves the audio session in `.record`, which would play back silently.
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.play()
            player = newPlayer
            playingURL = url
        } catch {
            print("[Recording] Playback failed:", error)
            stop()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        playingURL = nil
    }
}

extension RecordingPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
    }
}

struct ReportView: View {
    @Environment(\.presentationMode) private var presentationMode
    let reports: Asleep.Reports?
    let sessionList: [Asleep.Model.SleepSession]

    @State private var currentIndex: Int = 0
    @State private var currentReport: Asleep.Model.Report?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var recordingFiles: [Asleep.Model.RecordingFile] = []
    @StateObject private var recordingPlayer = RecordingPlayer()

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
        .onDisappear {
            recordingPlayer.stop()
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
                Text("Time Range : \(report.session.startTime.fullDateString) ~ \(report.session.endTime?.fullDateString ?? "N/A")")
                // v3.3.0: the analysed range above can be wider than the range actually recorded,
                // e.g. when tracking was stopped with an explicit end time.
                Text("Measured : \(report.session.measurementStartTime?.fullDateString ?? "N/A") ~ \(report.session.measurementEndTime?.fullDateString ?? "N/A")")
                Text("Unexpected End Time : \(report.session.unexpectedEndTime?.fullDateString ?? "N/A")")
                Text("Session State : \(report.session.state.rawValue)")
                Text("Missing Data Ratio : \(String(format: "%.1f%%", report.missingDataRatio * 100))")
                Text("Peculiarities : \(report.peculiarities.description)")
            }
            .font(.system(size: 14))
            .textSelection(.enabled)

            Divider()

            // Sleep Stages Section
            sleepStagesSection(report: report)

            Divider()

            // Snoring Stages Section
            snoringStagesSection(report: report)

            Divider()

            // Recordings Section
            recordingsSection()
        }
        .padding(.vertical, 16)
    }

    /// Lists the segments kept for the shown session and plays one on tap. Only sessions recorded on
    /// this device (into this branch's `recordingPath`) have files; anything else shows the empty
    /// message.
    @ViewBuilder
    func recordingsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recordings")
                .font(.headline)

            if recordingFiles.isEmpty {
                Text("No recordings were kept for this session.")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(recordingFiles, id: \.segmentIndex) { file in
                        recordingRow(file)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func recordingRow(_ file: Asleep.Model.RecordingFile) -> some View {
        let isPlaying = file.filePath != nil && file.filePath == recordingPlayer.playingURL

        Button {
            if let url = file.filePath {
                recordingPlayer.toggle(url)
            }
        } label: {
            Text("\(isPlaying ? "▶ " : "")\(recordingLabel(file))")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func recordingLabel(_ file: Asleep.Model.RecordingFile) -> String {
        var label = String(format: "#%03d", file.segmentIndex)

        // The timestamp arrives as `yyyy-MM-dd HH:mm:ss...`; only the time part is shown.
        if let timestamp = file.timestamp, timestamp.count >= 19 {
            let start = timestamp.index(timestamp.startIndex, offsetBy: 11)
            let end = timestamp.index(timestamp.startIndex, offsetBy: 19)
            label += "  \(timestamp[start..<end])"
        }
        if file.isSnoringDetected {
            label += String(format: "  snoring(%.1f)", file.snoreIntensity)
        }
        if file.isBreathDetected {
            label += String(format: "  breath(%.1f)", file.breathSeverity)
        }
        label += String(format: "  %.1fdB", file.maxDb)

        return label
    }

    /// Reads the files back through a `RecordingFileManager` built on the same `recordingPath` the
    /// tracking manager was given - a different path always lists nothing.
    func loadRecordingFiles(sessionId: String) {
        let fileManager = Asleep.createRecordingFileManager(recordingPath: MainView.ViewModel.recordingPath)
        recordingFiles = fileManager.getAllSegments(sessionId: sessionId).filter { $0.filePath != nil }
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
        // The listed files belong to the report being replaced, so drop them with the playback.
        recordingPlayer.stop()
        recordingFiles = []

        Task {
            do {
                guard let reports = reports else {
                    throw NSError(domain: "ReportView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Reports manager is not initialized"])
                }

                let report = try await reports.report(sessionId: session.sessionId)

                await MainActor.run {
                    currentReport = report
                    loadRecordingFiles(sessionId: report.session.id)
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
