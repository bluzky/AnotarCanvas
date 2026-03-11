//
//  StepNumberTool.swift
//  AnotarCanvas
//

import SwiftUI
import AppKit

public extension DrawingTool {
    static let stepNumber = DrawingTool(id: "stepNumber")
}

/// Tool for placing auto-incrementing numbered circles.
/// Click-to-place: each click creates the next numbered step.
public struct StepNumberTool: CanvasTool {
    public let toolType: DrawingTool = .stepNumber
    public let name: String = "Step Number"
    public let category: ToolCategory = .annotation
    public let cursor: NSCursor = .crosshair

    public var capabilities: Set<ToolCapability> {
        [.stroke]
    }

    public init() {}

    // MARK: - Manifest

    public static let manifest = ToolManifest(
        tool: StepNumberTool(),
        discriminator: "stepNumber",
        interactiveView: { obj, isSelected, vm in
            AnyView(StepNumberObjectView(object: obj, isSelected: isSelected))
        },
        exportView: { obj in
            AnyView(ExportStepNumberObjectView(object: obj))
        }
    )

    // MARK: - Click Handling

    public func handleClick(
        at point: CGPoint,
        viewModel: CanvasViewModel,
        shiftHeld: Bool
    ) {
        print("[StepNumberTool] handleClick at \(point), tool registered: \(ToolRegistry.shared.tool(for: .stepNumber) != nil)")
        let attrs = viewModel.currentToolAttributes
        let strokeColor = attrs[ObjectAttributes.strokeColor] as? Color ?? .red
        let strokeWidth = attrs[ObjectAttributes.strokeWidth] as? CGFloat ?? 2.0
        let strokeStyle = attrs[ObjectAttributes.strokeStyle] as? StrokeStyleType ?? .solid
        let textColor = attrs[ObjectAttributes.textColor] as? Color ?? .red

        // Size driven by fontSize attribute from the app
        let fontSize = attrs[ObjectAttributes.fontSize] as? CGFloat ?? 24
        let diameter = fontSize * 1.4
        let objectSize = CGSize(width: diameter, height: diameter)

        // Background color from fill attributes
        let fillOpacity = attrs[ObjectAttributes.fillOpacity] as? CGFloat ?? 1.0
        let backgroundColor: Color
        if fillOpacity > 0, let fillColor = attrs[ObjectAttributes.fillColor] as? Color {
            backgroundColor = fillColor
        } else {
            backgroundColor = .white
        }

        let nextNumber = Self.nextStepNumber(in: viewModel)

        let halfSize = diameter / 2
        let obj = StepNumberObject(
            position: CGPoint(x: point.x - halfSize, y: point.y - halfSize),
            size: objectSize,
            number: nextNumber,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            strokeStyle: strokeStyle,
            textColor: textColor,
            backgroundColor: backgroundColor
        )
        viewModel.addObject(obj)
    }

    /// Compute the next step number by finding the max existing step number on the canvas.
    private static func nextStepNumber(in viewModel: CanvasViewModel) -> Int {
        var maxNumber = 0
        for obj in viewModel.objects {
            if let step = obj.asType(StepNumberObject.self) {
                maxNumber = max(maxNumber, step.number)
            }
        }
        return maxNumber + 1
    }
}
