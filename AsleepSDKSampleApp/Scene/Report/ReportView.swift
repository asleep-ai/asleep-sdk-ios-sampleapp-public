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
            Text("Time Range: \(report.session.startTime.dateString + (report.session.endTime.map { " ~ " + $0.dateString } ?? ""))")
            Text("Session State: \(report.session.state.rawValue)")
            Text("Validity: \(report.validity.rawValue)")
            stagesView(report: report)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func stagesView(report: Asleep.Model.Report) -> some View {
        
        VStack(alignment: .leading, spacing: 10) {
            statView(stat: report.stat)
            
            Text("Sleep Stages")
                .font(.body.bold())
                .padding(.top, 4)
            if let sleepStages = report.session.sleepStages {
                Text("[\(sleepStages.map{ "\($0.rawValue)" }.joined(separator: ", "))]")
            }
            
            Text("Breath Stages")
                .font(.body.bold())
                .padding(.top, 4)

            if let breathStages = report.session.osaStages {
                Text("[\(breathStages.map{ "\($0.rawValue)" }.joined(separator: ", "))]")
            }
        }
    }
    
    @ViewBuilder
    func statView(stat: Asleep.Model.Stat?) -> some View {
        VStack(alignment: .leading) {
            Text("Stat")
                .font(.body.bold())
                .padding(.vertical, 4)

            Text("SleepLatency: \((stat?.sleepLatency).string)")
            Text("WakeupLatency: \((stat?.wakeupLatency).string)")
            Text("SleepTime: \((stat?.sleepTime).string)")
            Text("WakeTime: \((stat?.wakeTime).string)")
            Text("TimeInWake: \((stat?.timeInWake).string)")
            Text("TimeInSleep: \((stat?.timeInSleep).string)")
            Text("TimeInBed: \((stat?.timeInBed).string)")
            Text("TimeInSleepPeriod: \((stat?.timeInSleepPeriod).string)")
            Text("TimeInREM: \((stat?.timeInRem).string)")
            Text("TimeInLight: \((stat?.timeInLight).string)")
            Text("TimeInDeep: \((stat?.timeInDeep).string)")
            Text("TimeInDeep: \((stat?.timeInDeep).string)")
            Text("TimeInStableBreath: \((stat?.timeInStableBreath).string)")
            Text("TimeInUnstableBreath: \((stat?.timeInUnstableBreath).string)")
            Text("SleepEfficiency: \((stat?.sleepEfficiency).string)")
            Text("WakeRatio: \((stat?.wakeRatio).string)")
            Text("SleepRatio: \((stat?.sleepRatio).string)")
            Text("RemRatio: \((stat?.remRatio).string)")
            Text("LightRatio: \((stat?.lightRatio).string)")
            Text("DeepRatio: \((stat?.deepRatio).string)")
            Text("StableBreathRatio: \((stat?.stableBreathRatio).string)")
            Text("UnstableBreathRatio: \((stat?.unstableBreathRatio).string)")
            Text("BreathingPattern: \((stat?.breathingPattern).string)")
            Text("EstimatedAhi: \((stat?.estimatedAhi).string)")
        }
    }
}

private extension Optional {
    var string: String {
        self.map{ "\($0)" } ?? "N/A"
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyReport: Asleep.Model.Report?
        let jsonData = """
        {
          "timezone" : "Asia/Seoul",
          "validity" : "VALID",
          "session" : {
            "osaStages" : [
              0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0
            ],
            "id" : "20231004040255_zsv1s",
            "state" : "COMPLETE",
            "startTime" : "2023-10-04T13:02:55+09:00",
            "endTime" : "2023-10-04T13:23:41+09:00",
            "sleepStages" : [
              0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1
            ]
          },
          "stat" : {
            "timeInWake" : 0,
            "timeInSleepPeriod" : 900,
            "timeInDeep" : 0,
            "lightRatio" : 1,
            "timeInRem" : 0,
            "estimatedAhi" : 0,
            "remRatio" : 0,
            "wakeupLatency" : 0,
            "wakeTime" : "2023-10-04T13:23:41+09:00",
            "stableBreathRatio" : 1,
            "sleepRatio" : 1,
            "wakeRatio" : 0,
            "timeInStableBreath" : 900,
            "sleepLatency" : 300,
            "timeInBed" : 1246,
            "deepRatio" : 0,
            "timeInLight" : 900,
            "timeInUnstableBreath" : 0,
            "unstableBreathRatio" : 0,
            "breathingPattern" : "VERY_STABLE",
            "timeInSleep" : 900,
            "sleepEfficiency" : 0.75,
            "sleepTime" : "2023-10-04T13:07:55+09:00"
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
