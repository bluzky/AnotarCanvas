# AnotarCanvas

A Swift Package providing a FigJam-style infinite canvas for macOS apps. Drop it in to get a fully-featured drawing surface with built-in tools, selection, undo/redo, clipboard, and document persistence — ready to embed in any SwiftUI macOS application.

## Requirements

- macOS 14+
- Swift 6 / Xcode 15+

## Installation

Add the package via Swift Package Manager in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bluzky/AnotarCanvas.git", from: "1.0.0")
]
```

Or add it directly in Xcode: **File → Add Package Dependencies** and paste the repository URL.

## Features

- Infinite panning and zooming canvas
- Built-in tools: select, hand, text, rectangle, oval, diamond, triangle, star, line, arrow, pencil
- Multi-selection with marquee drag and shift-click
- Resize and rotate handles on selected objects
- Embedded text inside shapes
- Image objects (paste or drag-drop)
- Undo / redo stack
- Clipboard copy/paste with type-safe serialization (`CodableObjectRegistry`)
- Document persistence via `AnnotaDocument` (JSON-based `.annota` file format)
- Protocol-oriented design — add custom object types and tools without touching core code
- Swift 6 strict concurrency safe (no `@unchecked` workarounds on public APIs)

## Quick Start

```swift
import SwiftUI
import AnotarCanvas

struct ContentView: View {
    @StateObject private var viewModel = CanvasViewModel()

    var body: some View {
        CanvasView(viewModel: viewModel)
    }
}
```

## Architecture

### Core Protocols

| Protocol | Purpose |
|---|---|
| `CanvasObject` | Base for all drawable objects — position, size, rotation, hit-test |
| `CopyableCanvasObject` | Adds clipboard serialization (`Codable` + `copied()`) |
| `FillableObject` | Fill color and opacity |
| `StrokableObject` | Stroke color, width, and style |
| `TextContentObject` | Embedded text with font and alignment |
| `CanvasTool` | Gesture handling and object creation for a toolbar tool |

### Key Types

| Type | Role |
|---|---|
| `CanvasViewModel` | Single source of truth — objects, selection, active tool, undo stack |
| `CanvasView` | SwiftUI view — renders objects and handles all gestures |
| `ToolRegistry` | Maps `DrawingTool` identifiers to `CanvasTool` implementations |
| `ObjectViewRegistry` | Maps object types to their SwiftUI interactive and export views |
| `CodableObjectRegistry` | Maps type discriminator strings to encode/decode closures |
| `ToolManifest<Obj>` | Bundles a tool with its view and codable registrations in one call |
| `ObjectManifest<Obj>` | Same as `ToolManifest` but for types with no toolbar tool (e.g. images) |
| `ViewportState` | Tracks pan offset and zoom scale; converts between screen and canvas coordinates |
| `AnnotaDocument` | `ReferenceFileDocument` for SwiftUI document-based apps |

### Adding a Custom Object Type

1. Define your model conforming to `CopyableCanvasObject` (and any feature protocols).
2. Create a SwiftUI view for interactive editing and one for export.
3. Implement `CanvasTool` if the object has a toolbar entry.
4. Register everything at app startup via `ToolRegistry.shared.register(_: ToolManifest)`.

## Documentation

- [API Reference](docs/AnotarCanvas-API.md) — full public API, all types and protocols
- [Adding a Tool](docs/adding-a-tool.md) — step-by-step guide for custom tools and object types

## License

MIT
