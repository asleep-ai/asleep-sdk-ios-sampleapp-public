//  SleepStageGraphModels.swift - Copyright 2023 Asleep

import SwiftUI

struct Slice {
    let value: Float  // Percentage (0-100)
    let color: Color
    let target: Bool
    let isTransparent: Bool

    init(value: Float, color: Color, target: Bool, isTransparent: Bool = false) {
        self.value = value
        self.color = color
        self.target = target
        self.isTransparent = isTransparent
    }
}

func makeSlice(
    stages: [Int]?,
    targetValue: Int,
    mainColor: Color,
    otherColor: Color
) -> [Slice] {
    guard let stages = stages, !stages.isEmpty else { return [] }

    var slices: [Slice] = []
    var firstItemCnt: Float = 0
    var secondItemCnt: Float = 0

    for stage in stages {
        if stage == targetValue {
            if secondItemCnt > 0 {
                let percentage = (secondItemCnt / Float(stages.count)) * 100
                slices.append(Slice(value: percentage, color: otherColor, target: false, isTransparent: false))
                secondItemCnt = 0
            }
            firstItemCnt += 1
        } else {
            if firstItemCnt > 0 {
                let percentage = (firstItemCnt / Float(stages.count)) * 100
                slices.append(Slice(value: percentage, color: mainColor, target: true, isTransparent: false))
                firstItemCnt = 0
            }
            secondItemCnt += 1
        }
    }

    if firstItemCnt != 0 {
        let percentage = (firstItemCnt / Float(stages.count)) * 100
        slices.append(Slice(value: percentage, color: mainColor, target: true, isTransparent: false))
    } else if secondItemCnt != 0 {
        let percentage = (secondItemCnt / Float(stages.count)) * 100
        slices.append(Slice(value: percentage, color: otherColor, target: false, isTransparent: true))
    }

    return slices
}
