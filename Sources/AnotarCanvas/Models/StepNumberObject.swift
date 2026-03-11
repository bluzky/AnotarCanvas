//
//  StepNumberObject.swift
//  AnotarCanvas
//

import SwiftUI

@MainActor
public struct StepNumberObject: CanvasObject, StrokableObject, CopyableCanvasObject, @preconcurrency Codable {
    // MARK: - CanvasObject
    public let id: UUID
    public var position: CGPoint
    public var size: CGSize
    public var rotation: CGFloat = 0
    public var isLocked: Bool = false
    public var zIndex: Int = 0

    // MARK: - StrokableObject
    public var strokeColor: Color
    public var strokeWidth: CGFloat = 2
    public var strokeStyle: StrokeStyleType = .solid

    // MARK: - StepNumber-specific
    public var number: Int
    public var textColor: Color
    public var backgroundColor: Color

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        position: CGPoint,
        size: CGSize,
        number: Int,
        strokeColor: Color = .red,
        strokeWidth: CGFloat = 2,
        strokeStyle: StrokeStyleType = .solid,
        textColor: Color = .red,
        backgroundColor: Color = .white,
        rotation: CGFloat = 0,
        isLocked: Bool = false,
        zIndex: Int = 0
    ) {
        self.id = id
        self.position = position
        self.size = size
        self.number = number
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.strokeStyle = strokeStyle
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.rotation = rotation
        self.isLocked = isLocked
        self.zIndex = zIndex
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, position, size, rotation, isLocked, zIndex
        case strokeColor, strokeWidth, strokeStyle
        case number, textColor, backgroundColor
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        position = try container.decode(CGPoint.self, forKey: .position)
        size = try container.decode(CGSize.self, forKey: .size)
        rotation = try container.decodeIfPresent(CGFloat.self, forKey: .rotation) ?? 0
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        zIndex = try container.decodeIfPresent(Int.self, forKey: .zIndex) ?? 0
        let codableStroke = try container.decode(CodableColor.self, forKey: .strokeColor)
        strokeColor = codableStroke.color
        strokeWidth = try container.decodeIfPresent(CGFloat.self, forKey: .strokeWidth) ?? 2
        strokeStyle = try container.decodeIfPresent(StrokeStyleType.self, forKey: .strokeStyle) ?? .solid
        number = try container.decode(Int.self, forKey: .number)
        let codableText = try container.decode(CodableColor.self, forKey: .textColor)
        textColor = codableText.color
        let codableBg = try container.decodeIfPresent(CodableColor.self, forKey: .backgroundColor)
        backgroundColor = codableBg?.color ?? .white
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(position, forKey: .position)
        try container.encode(size, forKey: .size)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(isLocked, forKey: .isLocked)
        try container.encode(zIndex, forKey: .zIndex)
        try container.encode(CodableColor(strokeColor), forKey: .strokeColor)
        try container.encode(strokeWidth, forKey: .strokeWidth)
        try container.encode(strokeStyle, forKey: .strokeStyle)
        try container.encode(number, forKey: .number)
        try container.encode(CodableColor(textColor), forKey: .textColor)
        try container.encode(CodableColor(backgroundColor), forKey: .backgroundColor)
    }

    // MARK: - Copy

    public func copied(newId: UUID, zIndex: Int, offset: CGPoint) -> StepNumberObject {
        StepNumberObject(
            id: newId,
            position: CGPoint(x: position.x + offset.x, y: position.y + offset.y),
            size: size,
            number: number,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            strokeStyle: strokeStyle,
            textColor: textColor,
            backgroundColor: backgroundColor,
            rotation: rotation,
            isLocked: false,
            zIndex: zIndex
        )
    }

    // MARK: - CanvasObject

    public func contains(_ point: CGPoint) -> Bool {
        let localPoint = rotation != 0 ? transformToLocal(point) : point
        let center = CGPoint(x: position.x + size.width / 2, y: position.y + size.height / 2)
        let radius = size.width / 2 + 4 // 4pt padding for easier hit testing
        return hypot(localPoint.x - center.x, localPoint.y - center.y) <= radius
    }

    public var isResizable: Bool { false }

    public func boundingBox() -> CGRect {
        CGRect(origin: position, size: size)
    }
}

// MARK: - CustomizableObject

extension StepNumberObject: CustomizableObject {
    public mutating func applyCustomAttributes(_ attributes: [String: Any]) {
        if let color = attributes["textColor"] as? Color {
            self.textColor = color
        }
        if let color = attributes["backgroundColor"] as? Color {
            self.backgroundColor = color
        }
        if let opacity = attributes["fillOpacity"] as? CGFloat, opacity > 0,
           let color = attributes["fillColor"] as? Color {
            self.backgroundColor = color
        }
    }

    public func getCustomAttributes() -> [String: Any] {
        [
            "textColor": textColor,
            "backgroundColor": backgroundColor,
        ]
    }
}
