//  SleepStagesView.swift - Copyright 2023 Asleep

import SwiftUI

struct SleepStagesView: View {
    let awakeSlices: [Slice]
    let remSlices: [Slice]
    let lightSlices: [Slice]
    let deepSlices: [Slice]
    let startTime: String
    let endTime: String

    /// Width reserved for the row labels so every bar starts at the same x position.
    private let labelWidth: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Four sleep stage bars, each labelled with the stage it represents
            VStack(spacing: 4) {
                stageRow(label: "Awake", slices: awakeSlices)
                stageRow(label: "REM", slices: remSlices)
                stageRow(label: "Light", slices: lightSlices)
                stageRow(label: "Deep", slices: deepSlices)
            }

            HStack {
                Spacer()
                    .frame(width: labelWidth)
                Text(startTime)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
                Text(endTime)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder
    private func stageRow(label: String, slices: [Slice]) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: labelWidth, alignment: .leading)

            StackedBarView(slices: slices, height: 24)
                .cornerRadius(4)
        }
    }
}
