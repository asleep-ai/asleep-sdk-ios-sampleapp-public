//  SampleView.swift - Copyright 2023 Asleep

import SwiftUI

extension MainView {
    enum Sheet: Identifiable {
        var id: Self { self }
        case report
        case reportList
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
    
    var body: some View {
        VStack(alignment: .center) {
            ConfigView(apiKey: $apiKey,
                       isTracking: $viewModel.isTracking,
                       userId: $userId)
            LoggerView(error: $viewModel.error,
                       isTracking: $viewModel.isTracking,
                       startTime: $startTime,
                       sessionId: $viewModel.sessionId,
                       sequenceNumber: $viewModel.sequenceNumber)
            
            if !(viewModel.sessionId ?? "").isEmpty {
                getReportButton
                getReportListButton
            }
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
        .sheet(item: $activeSheet) {
            switch $0 {
            case .report:
                ReportView(report: viewModel.createdReport)
            case .reportList:
                ReportListView(reports: viewModel.reports, reportList: viewModel.createdReportList)
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
    var getReportListButton: some View {
        Button("Get Report List") {
            Task {
                let today = Date()
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
                if let reportList = try? await viewModel.reports?.reports(fromDate: yesterday.simpleDateString, toDate: today.simpleDateString) {
                    viewModel.createdReportList = reportList
                    activeSheet = .reportList
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
                startTracking(hasConfig: viewModel.config != nil)
            }
        }.buttonStyle(CommonButtonStyle())
    }
    
    private func startTracking(hasConfig: Bool) {
        viewModel.sessionId = ""
        if hasConfig {
            viewModel.trackingManager?.startTracking()
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
        viewModel.trackingManager?.stopTracking()
        viewModel.initReport()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

