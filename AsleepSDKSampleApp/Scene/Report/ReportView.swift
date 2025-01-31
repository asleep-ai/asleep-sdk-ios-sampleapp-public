//  ReportView.swift - Copyright 2023 Asleep

import SwiftUI
import AsleepSDK

struct ReportView: View {
    @Environment(\.presentationMode) private var presentationMode
    let report: Asleep.Model.Report?
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
            if let report = self.report {
                ScrollView {
                    detailView(report: report)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    @ViewBuilder
    func detailView(report: Asleep.Model.Report) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(report.session.id)
                .font(.title2.bold())
            Text("Created Timezone: \(report.session.createdTimezone.description)")
            Text("Time Range: \(report.session.startTime.fullDateString + (report.session.endTime.map { " ~ " + $0.fullDateString } ?? ""))")
            Text("Unexpected End Time: \(report.session.unexpectedEndTime?.description ?? "N/A")")
            Text("Session State: \(report.session.state.rawValue)")
            Text("Missing Data Ratio: \(String(report.missingDataRatio))")
            Text("Preculiarities: \(report.peculiarities.description)")
            stagesView(report: report)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func stagesView(report: Asleep.Model.Report) -> some View {
        
        VStack(alignment: .leading, spacing: 10) {
            Text("Sleep Stages")
                .font(.body.bold())
                .padding(.top, 4)
            if let sleepStages = report.session.sleepStages {
                Text("[\(sleepStages.map(String.init).joined(separator: ", "))]")
            }
            
            if report.stat != nil {
                Text("""
                    SleepEfficiency: \(report.stat?.sleepEfficiency?.description ?? "nil")
                    SleepLatency: \(report.stat?.sleepLatency?.description ?? "nil")
                    WakeupLatency: \(report.stat?.wakeupLatency?.description ?? "nil")
                    SleepTime: \(report.stat?.sleepTime?.description ?? "nil")
                    WakeTime: \(report.stat?.wakeTime?.description ?? "nil")
                    LightLatency: \(report.stat?.lightLatency?.description ?? "nil")
                    DeepLatency: \(report.stat?.deepLatency?.description ?? "nil")
                    RemLatency: \(report.stat?.remLatency?.description ?? "nil")
                    TimeInWake: \(report.stat?.timeInWake?.description ?? "nil")
                    TimeInSleep: \(report.stat?.timeInSleep?.description ?? "nil")
                    TimeInBed: \(report.stat?.timeInBed?.description ?? "nil")
                    TimeInSleepPeriod: \(report.stat?.timeInSleepPeriod?.description ?? "nil")
                    TimeInREM: \(report.stat?.timeInRem?.description ?? "nil")
                    TimeInLight: \(report.stat?.timeInLight?.description ?? "nil")
                    TimeInDeep: \(report.stat?.timeInDeep?.description ?? "nil")
                    WakeRatio: \(report.stat?.wakeRatio?.description ?? "nil")
                    SleepRatio: \(report.stat?.sleepRatio?.description ?? "nil")
                    RemRatio: \(report.stat?.remRatio?.description ?? "nil")
                    LightRatio: \(report.stat?.lightRatio?.description ?? "nil")
                    DeepRatio: \(report.stat?.deepRatio?.description ?? "nil")
                    """)
            } else {
                Text("Stat is nil")
            }
            
            Text("Snoring Stages")
                .font(.body.bold())
                .padding(.top, 4)
            if let snoringStages = report.session.snoringStages {
                Text("[\(snoringStages.map(String.init).joined(separator: ", "))]")
            }
            if report.stat != nil {
                Text("""
                    TimeInSnoring: \(report.stat?.timeInSnoring?.description ?? "nil")
                    TimeInNoSnoring: \(report.stat?.timeInNoSnoring?.description ?? "nil")
                    SnoringRatio: \(report.stat?.snoringRatio?.description ?? "nil")
                    NoSnoringRatio: \(report.stat?.noSnoringRatio?.description ?? "nil")
                    SnoringCount: \(report.stat?.snoringCount?.description ?? "nil")
                    """)
            }
        }
    }
}
