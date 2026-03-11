//
//  StepNumberObjectView.swift
//  AnotarCanvas
//

import SwiftUI

private struct StepNumberCircle: View {
    let object: StepNumberObject

    var body: some View {
        ZStack {
            Circle()
                .fill(object.backgroundColor)
                .frame(width: object.size.width, height: object.size.height)
            Circle()
                .stroke(object.strokeColor, style: object.swiftUIStrokeStyle)
                .frame(width: object.size.width, height: object.size.height)
            Text("\(object.number)")
                .font(.system(size: object.size.width * 0.5, weight: .bold, design: .rounded))
                .foregroundColor(object.textColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }
}

struct StepNumberObjectView: View {
    let object: StepNumberObject
    var isSelected: Bool = false

    var body: some View {
        StepNumberCircle(object: object)
            .rotationEffect(.radians(object.rotation))
            .position(
                x: object.position.x + object.size.width / 2,
                y: object.position.y + object.size.height / 2
            )
    }
}

struct ExportStepNumberObjectView: View {
    let object: StepNumberObject

    var body: some View {
        StepNumberCircle(object: object)
            .rotationEffect(.radians(object.rotation))
            .position(
                x: object.position.x + object.size.width / 2,
                y: object.position.y + object.size.height / 2
            )
    }
}
