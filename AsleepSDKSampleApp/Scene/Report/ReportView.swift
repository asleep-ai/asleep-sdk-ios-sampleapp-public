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
            Text("Time Range: \(report.session.startTime.dateString + (report.session.endTime.map { " ~ " + $0.dateString } ?? ""))")
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
            Text("Stat")
                .font(.body.bold())
                .padding(.top, 4)
            Text("\(report.stat?.description ?? "null")")
            
            Text("Sleep Stages")
                .font(.body.bold())
                .padding(.top, 4)
            if let sleepStages = report.session.sleepStages {
                Text("[\(sleepStages.map(String.init).joined(separator: ", "))]")
            }
            
            Text("Breath Stages")
                .font(.body.bold())
                .padding(.top, 4)
            if let breathStages = report.session.breathStages {
                Text("[\(breathStages.map(String.init).joined(separator: ", "))]")
            }
        }
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyReport: Asleep.Model.Report?
        let jsonData = """
        {
            "timezone": "Asia/Seoul",
            "peculiarities": [],
            "missingDataRatio": 0.0,
            "session": {
                "id": "20230914124256_8ramp",
                "state": "COMPLETE",
                "startTime": "2023-09-14T21:42:56+09:00",
                "endTime":"2023-09-14T22:08:34+09:00",
                "sleepStages": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
                "breathStages": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            },
            "stat": {
                "sleepEfficiency": 0.8,
                "sleepLatency": 300,
                "sleepTime": "2023-09-14T21:47:56+09:00",
                "wakeupLatency": 0,
                "wakeTime": "2023-09-14T22:08:34+09:00",
                "timeInWake": 0,
                "timeInSleep": 1200,
                "timeInBed": 1538,
                "timeInSleepPeriod": 1200,
                "timeInRem": 300,
                "timeInLight": 900,
                "timeInDeep": 0,
                "timeInStableBreath": 1200,
                "timeInUnstableBreath": 0,
                "wakeRatio": 1,
                "sleepRatio": 1,
                "remRatio": 0.25,
                "lightRatio": 0.75,
                "deepRatio": 0,
                "stableBreathRatio": 1,
                "unstableBreathRatio": 0,
                "breathingPattern": "STABLE_BREATH",
                "breathingIndex": 0
            }
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        dummyReport = try? decoder.decode(Asleep.Model.Report.self, from: jsonData)
        
        return Group {
            if let report = dummyReport {
                ReportView(report: report)
            } else {
                Text("Failed to load dummy report")
            }
        }
    }
}
