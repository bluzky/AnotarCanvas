//
//  HighlightTool.swift
//  AnotarCanvas
//

import SwiftUI

public extension DrawingTool {
    public static let highlight = DrawingTool(id: "highlight")
}

/// Freehand highlight tool — draws a semi-transparent, wide stroke.
/// Uses fixed stroke width and opacity regardless of toolbar settings.
public struct HighlightTool: CanvasTool {
    public let toolType: DrawingTool = .highlight

    public let name: String = "Highlight"
    public let category: ToolCategory = .drawing
    public let cursor: NSCursor = .crosshair

    /// No user-configurable stroke attributes — width and opacity are fixed
    public var capabilities: Set<ToolCapability> {
        []
    }

    /// Fixed highlight stroke width
    public static let strokeWidth: CGFloat = 20

    /// Fixed highlight opacity
    public static let strokeOpacity: Double = 0.4

    private let minPointDistance: CGFloat = 4
    private let minStrokeDistance: CGFloat = 3

    public init() {}

    // MARK: - Manifest

    public static let manifest = ToolManifest(
        tool: HighlightTool(),
        discriminator: "highlight",
        interactiveView: { obj, isSelected, vm in
            AnyView(HighlightObjectView(object: obj, isSelected: isSelected, viewModel: vm))
        },
        exportView: { obj in
            AnyView(ExportHighlightObjectView(object: obj))
        }
    )

    // MARK: - CanvasTool

    public func renderPreview(
        start: CGPoint,
        current: CGPoint,
        viewModel: CanvasViewModel
    ) -> AnyView {
        guard let pts = viewModel.currentToolAttributes["highlightPoints"] as? [CGPoint],
              pts.count >= 2 else {
            return AnyView(EmptyView())
        }

        let attrs = viewModel.currentToolAttributes
        let strokeColor = attrs["strokeColor"] as? Color ?? .yellow

        let preview = HighlightObject(
            points: pts,
            strokeColor: strokeColor
        )

        return AnyView(
            preview.smoothPath()
                .stroke(
                    strokeColor.opacity(Self.strokeOpacity),
                    style: StrokeStyle(lineWidth: Self.strokeWidth, lineCap: .round, lineJoin: .round)
                )
        )
    }

    public func handleDragChanged(
        start: CGPoint,
        current: CGPoint,
        viewModel: CanvasViewModel
    ) {
        var pts = viewModel.currentToolAttributes["highlightPoints"] as? [CGPoint] ?? []

        if pts.isEmpty {
            pts.append(start)
        }

        if let last = pts.last {
            let dx = current.x - last.x
            let dy = current.y - last.y
            if hypot(dx, dy) >= minPointDistance {
                pts.append(current)
            }
        }

        viewModel.currentToolAttributes["highlightPoints"] = pts
        viewModel.dragStartPoint = start
        viewModel.currentDragPoint = current
    }

    public func handleDragEnded(
        start: CGPoint,
        end: CGPoint,
        viewModel: CanvasViewModel,
        shiftHeld: Bool
    ) {
        defer {
            viewModel.currentToolAttributes["highlightPoints"] = nil
            viewModel.dragStartPoint = nil
            viewModel.currentDragPoint = nil
        }

        guard var pts = viewModel.currentToolAttributes["highlightPoints"] as? [CGPoint],
              !pts.isEmpty else { return }

        if let last = pts.last, hypot(end.x - last.x, end.y - last.y) > 0.5 {
            pts.append(end)
        }

        guard pts.count >= 2 else { return }
        let totalTravel = zip(pts, pts.dropFirst())
            .map { hypot($1.x - $0.x, $1.y - $0.y) }
            .reduce(0, +)
        guard totalTravel > minStrokeDistance else { return }

        let attrs = viewModel.currentToolAttributes
        let strokeColor = attrs["strokeColor"] as? Color ?? .yellow

        let highlight = HighlightObject(
            points: pts,
            strokeColor: strokeColor
        )
        viewModel.addObject(highlight)
    }
}
