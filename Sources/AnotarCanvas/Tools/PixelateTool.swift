//
//  PixelateTool.swift
//  AnotarCanvas
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

public extension DrawingTool {
    static let pixelate = DrawingTool(id: "pixelate")
}

/// Tool that creates a pixelated mosaic over a dragged region by sampling the background image.
/// Commits the result as an ImageObject (movable, resizable, undoable).
public struct PixelateTool: CanvasTool {
    public let toolType: DrawingTool = .pixelate
    public let name: String = "Pixelate"
    public let category: ToolCategory = .annotation
    public let cursor: NSCursor = .crosshair

    public var capabilities: Set<ToolCapability> { [] }

    private let blockSize: Int

    public init(blockSize: Int = 6) {
        self.blockSize = blockSize
    }

    // MARK: - Preview

    public func renderPreview(
        start: CGPoint,
        current: CGPoint,
        viewModel: CanvasViewModel
    ) -> AnyView {
        let rect = normalizedRect(from: start, to: current)
        guard rect.width > 2, rect.height > 2 else {
            return AnyView(EmptyView())
        }
        return AnyView(
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundColor(.blue)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        )
    }

    // MARK: - Drag

    public func handleDragChanged(
        start: CGPoint,
        current: CGPoint,
        viewModel: CanvasViewModel
    ) {
        if viewModel.dragStartPoint == nil {
            viewModel.dragStartPoint = start
        }
        viewModel.currentDragPoint = current
    }

    public func handleDragEnded(
        start: CGPoint,
        end: CGPoint,
        viewModel: CanvasViewModel,
        shiftHeld: Bool
    ) {
        defer {
            viewModel.dragStartPoint = nil
            viewModel.currentDragPoint = nil
        }

        let rect = normalizedRect(from: start, to: end)
        guard rect.width >= CGFloat(blockSize), rect.height >= CGFloat(blockSize) else { return }

        let pngData: Data?
        if let bgImage = viewModel.backgroundImage {
            pngData = generatePixelatedPNG(
                rect: rect,
                backgroundImage: bgImage,
                imageOrigin: viewModel.backgroundImageOrigin,
                scale: viewModel.backgroundImageScale
            )
        } else {
            pngData = generateFallbackMosaicPNG(size: rect.size)
        }

        guard let data = pngData else { return }

        let imageObject = ImageObject(
            position: rect.origin,
            size: rect.size,
            imageData: data,
            aspectRatio: rect.width / rect.height,
            maintainAspectRatio: false
        )
        viewModel.addObject(imageObject)
    }

    // MARK: - Pixelation from Background Image

    private func generatePixelatedPNG(
        rect: CGRect,
        backgroundImage: CGImage,
        imageOrigin: CGPoint,
        scale: CGFloat
    ) -> Data? {
        let width = Int(rect.width)
        let height = Int(rect.height)
        guard width > 0, height > 0 else { return nil }

        // Pixel rect within the background image
        let pixelX = imageOrigin.x + rect.origin.x * scale
        let pixelY = imageOrigin.y + rect.origin.y * scale
        let pixelW = rect.width * scale
        let pixelH = rect.height * scale

        // Crop the region from the background image
        let cropRect = CGRect(x: pixelX, y: pixelY, width: pixelW, height: pixelH)
        guard let cropped = backgroundImage.cropping(to: cropRect) else {
            return generateFallbackMosaicPNG(size: rect.size)
        }

        let srcW = cropped.width
        let srcH = cropped.height
        guard srcW > 0, srcH > 0 else { return generateFallbackMosaicPNG(size: rect.size) }

        // Draw cropped image into a CGContext to read pixel data.
        // CGContext.draw flips the image to fill the rect (origin bottom-left),
        // so pixel row 0 in memory = bottom of the image visually.
        guard let srcCtx = CGContext(
            data: nil,
            width: srcW,
            height: srcH,
            bitsPerComponent: 8,
            bytesPerRow: srcW * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return generateFallbackMosaicPNG(size: rect.size) }

        srcCtx.draw(cropped, in: CGRect(x: 0, y: 0, width: srcW, height: srcH))
        guard let srcData = srcCtx.data else { return generateFallbackMosaicPNG(size: rect.size) }
        let srcPtr = srcData.bindMemory(to: UInt8.self, capacity: srcW * srcH * 4)

        // Build output using CGContext (same coordinate system as source — no flip mismatch).
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let outCtx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let bs = blockSize
        let cols = (width + bs - 1) / bs
        let rows = (height + bs - 1) / bs

        for row in 0..<rows {
            for col in 0..<cols {
                let outX = col * bs
                let outY = row * bs
                let w = min(bs, width - outX)
                let h = min(bs, height - outY)

                // Sample center of this block from source.
                // Both contexts use CGContext (bottom-left origin) — no flip needed.
                let sampleX = min(Int(CGFloat(outX + w / 2) * scale), srcW - 1)
                let sampleY = min(Int(CGFloat(outY + h / 2) * scale), srcH - 1)
                let idx = (sampleY * srcW + sampleX) * 4

                let r = CGFloat(srcPtr[idx]) / 255.0
                let g = CGFloat(srcPtr[idx + 1]) / 255.0
                let b = CGFloat(srcPtr[idx + 2]) / 255.0

                outCtx.setFillColor(red: r, green: g, blue: b, alpha: 1.0)
                outCtx.fill(CGRect(x: outX, y: outY, width: w, height: h))
            }
        }

        guard let outImage = outCtx.makeImage() else { return nil }

        // Flip vertically: CGContext is bottom-left origin, SwiftUI expects top-left
        guard let flipCtx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        flipCtx.translateBy(x: 0, y: CGFloat(height))
        flipCtx.scaleBy(x: 1, y: -1)
        flipCtx.draw(outImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let flippedImage = flipCtx.makeImage() else { return nil }
        return pngData(from: flippedImage)
    }

    // MARK: - Fallback (no background image)

    private func generateFallbackMosaicPNG(size: CGSize) -> Data? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0, height > 0 else { return nil }

        let bs = blockSize
        let cols = (width + bs - 1) / bs
        let rows = (height + bs - 1) / bs

        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        for row in 0..<rows {
            for col in 0..<cols {
                let x = col * bs
                let y = row * bs
                let w = min(bs, width - x)
                let h = min(bs, height - y)

                let grey = CGFloat.random(in: 0.25...0.85)
                ctx.setFillColor(gray: grey, alpha: 1.0)
                ctx.fill(CGRect(x: x, y: y, width: w, height: h))
            }
        }

        guard let outImage = ctx.makeImage() else { return nil }
        return pngData(from: outImage)
    }

    // MARK: - PNG Encoding

    private func pngData(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }

    // MARK: - Helpers

    private func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
}
