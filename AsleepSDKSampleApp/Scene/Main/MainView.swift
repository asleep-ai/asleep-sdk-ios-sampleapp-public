//  SampleView.swift - Copyright 2023 Asleep

import SwiftUI

extension MainView {
    enum Sheet: Identifiable {
        var id: Self { self }
        case report
    }
}

struct MainView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    private let pastboard = UIPasteboard.general
    @StateObject private var viewModel = MainView.ViewModel()
    @AppStorage("sampleapp+apikey") private var apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? ""
    @AppStorage("sampleapp+userid") private var userId = ""
    @AppStorage("sampleapp+baseurl") private var baseUrl = ""
    @AppStorage("sampleapp+callbackurl") private var callbackUrl = ""
        
    @State private var startTime: Date?
    @State private var activeSheet: Sheet? = nil
    @State private var showInsufficientTimeAlert = false
    
    var body: some View {
        VStack(alignment: .center) {
            ConfigView(apiKey: $apiKey,
                       isTracking: .constant(viewModel.isTracking),
                       userId: $userId,
                       sessionId: viewModel.sessionId,
                       isLoading: viewModel.isLoading,
                       onViewReport: {
                           Task {
                               await fetchReportsAndShow()
                           }
                       })
            LoggerView(error: $viewModel.error,
                       isTracking: .constant(viewModel.isTracking),
                       startTime: $startTime,
                       sessionId: $viewModel.sessionId,
                       sequenceNumber: $viewModel.sequenceNumber,
                       errorLogs: $viewModel.errorLogs,
                       currentSleepStage: $viewModel.currentSleepStage,
                       currentSnoringStage: $viewModel.currentSnoringStage)

            tackingOnOffButton

            HStack {
                Image("AsleepLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)

                Text(version)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .padding(.bottom, 4)
        .edgesIgnoringSafeArea(.bottom)
        .onTapGesture {
            endTextEditing()
        }
        .onChange(of: viewModel.userId ?? "") {
            userId = $0
        }
        .onReceive(NotificationCenter.default.publisher(for: .startSleep), perform: { _ in
            if !viewModel.isTracking {
                startTracking(hasConfig: viewModel.config != nil)
            } else {
                print("Already tracking!")
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .stopSleep), perform: { _ in
            DispatchQueue.main.async {
                stopTracking()
            }
        })
        .sheet(item: $activeSheet) { _ in
            ReportView(reports: viewModel.reports, sessionList: viewModel.createdReportList ?? [])
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert(MainView.ViewModel.Strings.insufficientTimeTitle, isPresented: $showInsufficientTimeAlert) {
            Button(MainView.ViewModel.Strings.insufficientTimeCancel, role: .cancel) {
                showInsufficientTimeAlert = false
            }
            Button(MainView.ViewModel.Strings.insufficientTimeExit, role: .destructive) {
                performStopTracking()
            }
        } message: {
            Text(MainView.ViewModel.insufficientTimeAlertMessage)
        }
    }
}

private extension MainView {

    func fetchReportsAndShow() async {
        viewModel.isLoading = true
        defer { viewModel.isLoading = false }

        do {
            // Auto-initialize config if needed
            _ = try await viewModel.ensureConfig(
                apiKey: apiKey,
                userId: userId,
                baseUrl: .init(string: baseUrl),
                callbackUrl: .init(string: callbackUrl)
            )

            // Reports should be initialized by ensureConfig
            guard let reports = viewModel.reports else {
                viewModel.errorMessage = "Reports manager initialization failed."
                viewModel.showError = true
                return
            }

            let today = Date()
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else {
                viewModel.errorMessage = "Failed to calculate date range."
                viewModel.showError = true
                return
            }

            let reportList = try await reports.reports(fromDate: yesterday.simpleDateString, toDate: today.simpleDateString)
            viewModel.createdReportList = reportList
            activeSheet = .report
        } catch {
            viewModel.errorMessage = "Failed to fetch report list:\n\(error.localizedDescription)"
            viewModel.showError = true
        }
    }

    var tackingOnOffButton: some View {
        let trackingStatus: String
        let action: () -> Void

        switch viewModel.trackingState {
        case .idle:
            trackingStatus = "Start Tracking"
            action = { startTracking(hasConfig: viewModel.config != nil) }
        case .tracking, .interrupted:
            trackingStatus = "Stop Tracking"
            action = { stopTracking() }
        }

        return Button(trackingStatus, action: action)
            .buttonStyle(CommonButtonStyle())
            .disabled(viewModel.isLoading)
    }
    
    private func startTracking(hasConfig: Bool) {
        viewModel.sessionId = ""
        viewModel.clearErrors()
        viewModel.isLoading = true
        if hasConfig {
            // Basic usage
            viewModel.trackingManager?.startTracking()

            // Example: Start tracking with additional audio session options (v3.1.7+)
            // viewModel.trackingManager?.startTracking(additionalAudioSessionOptions: [.duckOthers])
            // viewModel.trackingManager?.startTracking(additionalAudioSessionOptions: [.allowAirPlay])
            // viewModel.trackingManager?.startTracking(additionalAudioSessionOptions: [.duckOthers, .allowAirPlay])
        } else {
            viewModel.initAsleepConfig(apiKey: apiKey,
                                       userId: userId,
                                       baseUrl: .init(string: baseUrl),
                                       callbackUrl: .init(string: callbackUrl))
        }
        startTime = Date()
        viewModel.sequenceNumber = nil
    }
    
    private func stopTracking() {
        // Check if tracking time meets minimum requirement
        guard let trackingStartTime = startTime else {
            // If startTime is nil, proceed with stop tracking
            performStopTracking()
            return
        }

        let elapsedTime = Date().timeIntervalSince(trackingStartTime)
        let elapsedMinutes = elapsedTime / 60

        if elapsedMinutes < Double(MainView.ViewModel.minTrackingMinutes) {
            // Show alert if tracking time is insufficient
            showInsufficientTimeAlert = true
            return
        }

        // Proceed with stop tracking
        performStopTracking()
    }

    private func performStopTracking() {
        viewModel.isLoading = true
        viewModel.trackingManager?.stopTracking()
        viewModel.initReport()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

