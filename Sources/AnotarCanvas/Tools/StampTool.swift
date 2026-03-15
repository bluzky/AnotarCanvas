//
//  StampTool.swift
//  AnotarCanvas
//

import SwiftUI
import AppKit

public extension DrawingTool {
    static let stamp = DrawingTool(id: "stamp")
}

/// Tool for placing emoji stickers on the canvas.
/// Click-to-place: user picks an emoji from the picker, then clicks to place it.
public struct StampTool: CanvasTool {
    public let toolType: DrawingTool = .stamp
    public let name: String = "Stamp"
    public let category: ToolCategory = .annotation
    public let cursor: NSCursor = .crosshair

    public var capabilities: Set<ToolCapability> {
        []
    }

    public init() {}

    // MARK: - Click Handling

    public func handleClick(
        at point: CGPoint,
        viewModel: CanvasViewModel,
        shiftHeld: Bool
    ) {
        let attrs = viewModel.currentToolAttributes
        let emoji = attrs["stampEmoji"] as? String ?? "⭐"

        guard let pngData = renderEmojiToPNG(emoji, size: 48) else { return }

        let stampSize = CGSize(width: 48, height: 48)
        let obj = ImageObject(
            position: CGPoint(x: point.x - stampSize.width / 2,
                              y: point.y - stampSize.height / 2),
            size: stampSize,
            imageData: pngData,
            aspectRatio: 1.0
        )
        viewModel.addObject(obj)
    }

    // MARK: - Emoji Rendering

    private func renderEmojiToPNG(_ emoji: String, size: CGFloat) -> Data? {
        let nsStr = emoji as NSString
        let font = NSFont.systemFont(ofSize: size)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = nsStr.size(withAttributes: attrs)

        let image = NSImage(size: textSize)
        image.lockFocus()
        nsStr.draw(at: .zero, withAttributes: attrs)
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return nil }
        return png
    }
}
