//  SampleView.swift - Copyright 2023 Asleep

import SwiftUI

extension MainView {
    enum Sheet: Identifiable {
        var id: Self { self }
        case report
    }
}

struct MainView: View {
    private let pastboard = UIPasteboard.general
    @StateObject private var viewModel = MainView.ViewModel()
    @AppStorage("sampleapp+apikey") private var apiKey = ""
    @AppStorage("sampleapp+userid") private var userId = ""
    @AppStorage("sampleapp+baseurl") private var baseUrlString = ""
    @AppStorage("sampleapp+callbackurl") private var callbackUrlString = ""
    
    @State private var startTime: Date?
    @State private var activeSheet: Sheet? = nil
    @State private var developerModeUserId = ""

    var body: some View {
        VStack(alignment: .center) {
            ConfigView(apiKey: $apiKey,
                       isDeveloperMode: $viewModel.isDeveloperMode,
                       isTracking: $viewModel.isTracking,
                       userId: viewModel.isDeveloperMode ? $developerModeUserId : $userId)
            LoggerView(error: $viewModel.error,
                       isDeveloperMode: $viewModel.isDeveloperMode,
                       isTracking: $viewModel.isTracking,
                       startTime: $startTime,
                       sessionId: $viewModel.sessionId,
                       sequenceNumber: $viewModel.sequenceNumber)
            
            if !(viewModel.sessionId ?? "").isEmpty {
                getReportButton
            }
            tackingOnOffButton
                
            Image("AsleepLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 50)
            
        }
        .padding()
        .padding(.bottom, 4)
        .edgesIgnoringSafeArea(.bottom)
        .onTapGesture {
            endTextEditing()
        }
        .onChange(of: viewModel.userId ?? "") {
            if viewModel.isDeveloperMode {
                developerModeUserId = $0
            } else {
                userId = $0
            }
        }
        .sheet(item: $activeSheet) {
            switch $0 {
            case .report:
                ReportView(report: viewModel.createdReport)
            }
        }
    }
}

private extension MainView {
    
    @ViewBuilder
    var getReportButton: some View {
        Button("Get Report") {
            Task {
                guard let sessionId: String = viewModel.sessionId else { return }
                
                if let report = try? await viewModel.reports?.report(sessionId: sessionId) {
                    viewModel.createdReport = report
                    activeSheet = .report
                }
            }
        }.buttonStyle(CommonButtonStyle())
    }
    
    @ViewBuilder
    var tackingOnOffButton: some View {
        let trackingStatus = viewModel.isTracking ? "Stop Tracking" : "Start Tracking"

        Button(trackingStatus) {
            if viewModel.isTracking {
                stopTracking()
            } else {
                startTracking(hasConfig: viewModel.isDeveloperMode ? false : viewModel.config != nil)
            }
        }.buttonStyle(CommonButtonStyle())
    }
    
    private func startTracking(hasConfig: Bool) {
        viewModel.sessionId = ""
        if hasConfig {
            viewModel.trackingManager?.startTracking()
        } else {
            developerModeUserId = ""
            viewModel.initAsleepConfig(apiKey: apiKey,
                                       userId: viewModel.isDeveloperMode ? developerModeUserId : userId,
                                       baseUrl: .init(string: baseUrlString),
                                       callbackUrl: .init(string: callbackUrlString))
        }
        startTime = Date()
        viewModel.sequenceNumber = nil
    }
    
    private func stopTracking() {
        viewModel.trackingManager?.stopTracking()
        viewModel.initReport()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

