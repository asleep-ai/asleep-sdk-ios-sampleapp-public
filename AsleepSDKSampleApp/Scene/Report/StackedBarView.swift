//  StackedBarView.swift - Copyright 2023 Asleep

import SwiftUI

struct StackedBarView: View {
    let slices: [Slice]
    let height: CGFloat

    init(slices: [Slice], height: CGFloat = 32) {
        self.slices = slices
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                var currentX: CGFloat = 0

                for slice in slices {
                    let width = (CGFloat(slice.value) / 100.0) * size.width

                    let rect = CGRect(
                        x: currentX,
                        y: 0,
                        width: width,
                        height: size.height
                    )

                    context.fill(
                        Path(rect),
                        with: .color(slice.color)
                    )

                    currentX += width
                }
            }
        }
        .frame(height: height)
    }
}
