//  SleepStagesView.swift - Copyright 2023 Asleep

import SwiftUI

struct SleepStagesView: View {
    let awakeSlices: [Slice]
    let remSlices: [Slice]
    let lightSlices: [Slice]
    let deepSlices: [Slice]
    let startTime: String
    let endTime: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Four sleep stage bars
            VStack(spacing: 4) {
                StackedBarView(slices: awakeSlices, height: 24)
                StackedBarView(slices: remSlices, height: 24)
                StackedBarView(slices: lightSlices, height: 24)
                StackedBarView(slices: deepSlices, height: 24)
            }
            .cornerRadius(4)

            HStack {
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
}
