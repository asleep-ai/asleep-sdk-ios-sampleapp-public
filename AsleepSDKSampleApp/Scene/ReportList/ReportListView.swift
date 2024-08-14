//  ReportListView.swift - Copyright 2024 Asleep

import SwiftUI
import AsleepSDK

struct ReportListView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedSessionId: String? = nil
    @State private var selectedReport: Asleep.Model.Report? = nil
    @State private var showSheet = false
    let reports: Asleep.Reports?
    let reportList: [Asleep.Model.SleepSession]?
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .padding(20)
            }
            
            if let reportList = self.reportList {
                listView(reportList: reportList)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    func listView(reportList: [Asleep.Model.SleepSession]) -> some View {
        List {
            ForEach(reportList.indices, id: \.self) { index in
                let item = reportList[index]
                VStack(alignment: .leading) {
                    Text("ID: \(item.sessionId)")
                    Text("State: \(item.state)")
                    Text("Start time: \(item.sessionStartTime.fullDateString)")
                    Text("End time: \(item.sessionEndTime?.fullDateString ?? "")")
                }
                .onTapGesture {
                    print(item)
                    selectedSessionId = item.sessionId
                    fetchReport()
                    showSheet = true
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            if let report = selectedReport {
                ReportView(report: report)
            } else {
                Text("Loading....")
            }
        }
    }
    
    func fetchReport() {
        guard let sessionId = selectedSessionId else { return }
        
        Task {
            if let fetchedReport = try? await reports?.report(sessionId: sessionId) {
                DispatchQueue.main.async {
                    selectedReport = fetchedReport
                }
            }
        }
    }
}
