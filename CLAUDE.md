# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build and launch the GUI app
make run-app

# Build GUI app bundle only (HeicToJpeg.app/)
make app

# Build CLI only
make cli

# Clean everything
make clean

# Build a specific target directly
swift build -c release --target HeicToJpeg   # GUI
swift build -c release --product heictojpeg  # CLI
```

The CLI tool installs to `.build/release/heictojpeg`. There are no tests or a linter configured.

### CLI usage

```
heictojpeg photo.heic photo2.heic           # individual files
heictojpeg -d ~/Pictures -o ~/out -r        # recursive directory
heictojpeg -q 85 photo.heic                 # custom quality (0–100, default 100)
```

## Architecture

Three SPM targets that share conversion logic via a library:

```
Sources/
  HeicConverter/   → library target "HeicConverter"
  CLI/             → executable target "CLI"  (product: heictojpeg)
  App/             → executable target "HeicToJpeg" (GUI)
Resources/
  Info.plist       → macOS app bundle metadata (used by `make app`)
Makefile           → builds HeicToJpeg.app bundle from SPM output + Info.plist
```

### HeicConverter (library)

`Converter` is a `Sendable` struct parameterised by `quality: Double` (0–1, default 1.0). Exposes:
- `convert(_:to:)` — single file
- `convertDirectory(at:outputDir:recursive:)` — batch, returns `[Result<URL,Error>]`

All types are `public`. Conversion pipeline: `CGImageSourceCreateWithURL` → `CGImageSourceCreateImageAtIndex` → EXIF orientation preserved via `kCGImagePropertyOrientation` → `CGImageDestinationCreateWithURL` (JPEG) → `CGImageDestinationFinalize`. Both `.heic` and `.heif` extensions are accepted.

### GUI app (Sources/App/)

SwiftUI macOS app targeting macOS 13+. Key files:

- **`HeicToJpegApp.swift`** — `@main` entry, single `Window` scene
- **`ContentView.swift`** — root layout; owns the whole-window `.onDrop` handler; composes `DropZoneView`, `LazyVGrid` of `ItemTileView`, and `FooterView`
- **`ConversionModel.swift`** — `@MainActor ObservableObject`; manages `[ConversionItem]` state, thumbnail loading, and conversion. CPU-bound work (ImageIO calls) runs in `Task.detached` and results are merged back on the main actor. Thumbnail loading returns `CGImage` (Sendable) from the detached task and converts to `NSImage` on the main actor.
- **`DropZoneView.swift`** — visual drop indicator + click-to-browse button; collapses from 190 px to 64 px when files are present
- **`ItemTileView.swift`** — grid tile: async thumbnail, filename, file size, status badge (spinner/checkmark/error)
- **`FooterView.swift`** — output directory picker (NSOpenPanel) + Clear All / Convert buttons

### Concurrency model

`ConversionModel` is `@MainActor`. `convertAll()` spawns a `Task` with `withTaskGroup`; each group task updates UI state on the main actor then awaits a `Task.detached` for the actual ImageIO work. This keeps the main actor free during conversion (no UI freezes). Thumbnail generation uses the same pattern — `CGImage` crosses the actor boundary (it is Sendable), `NSImage` is created on the main actor.
