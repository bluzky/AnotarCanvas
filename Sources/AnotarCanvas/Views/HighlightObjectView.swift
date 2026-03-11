//
//  HighlightObjectView.swift
//  AnotarCanvas
//

import SwiftUI

struct HighlightObjectView: View {
    let object: HighlightObject
    let isSelected: Bool
    @ObservedObject var viewModel: CanvasViewModel

    var body: some View {
        let bbox = object.boundingBox()
        let pad = object.strokeWidth / 2
        let frameSize = CGSize(
            width: max(object.size.width + object.strokeWidth, object.strokeWidth),
            height: max(object.size.height + object.strokeWidth, object.strokeWidth)
        )

        ZStack {
            object.localSmoothPath()
                .offsetBy(dx: pad, dy: pad)
                .stroke(
                    object.strokeColor.opacity(HighlightTool.strokeOpacity),
                    style: StrokeStyle(lineWidth: object.strokeWidth, lineCap: .round, lineJoin: .round)
                )
                .frame(width: frameSize.width, height: frameSize.height)

            if isSelected {
                Rectangle()
                    .stroke(Color.accentColor, lineWidth: 1)
                    .frame(width: bbox.width, height: bbox.height)
            }
        }
        .rotationEffect(.radians(object.rotation))
        .position(
            x: bbox.midX,
            y: bbox.midY
        )
    }
}

// MARK: - Export View

struct ExportHighlightObjectView: View {
    let object: HighlightObject

    var body: some View {
        let bbox = object.boundingBox()
        let pad = object.strokeWidth / 2
        let frameSize = CGSize(
            width: max(object.size.width + object.strokeWidth, object.strokeWidth),
            height: max(object.size.height + object.strokeWidth, object.strokeWidth)
        )
        object.localSmoothPath()
            .offsetBy(dx: pad, dy: pad)
            .stroke(
                object.strokeColor.opacity(HighlightTool.strokeOpacity),
                style: StrokeStyle(lineWidth: object.strokeWidth, lineCap: .round, lineJoin: .round)
            )
            .frame(width: frameSize.width, height: frameSize.height)
            .rotationEffect(.radians(object.rotation))
            .position(
                x: bbox.midX,
                y: bbox.midY
            )
    }
}
