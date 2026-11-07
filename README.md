# Pixel Bloom for iPad

A native SwiftUI color-by-number app for iPadOS 17 and later. No third-party dependencies, account, server, or network access required.

## Try it on a Mac

1. Open `PixelBloom.xcodeproj` in Xcode 15 or later.
2. Select the **PixelBloom** scheme and an iPad simulator.
3. Press **Run** (⌘R).
4. For a physical iPad, connect it, choose your Apple development team under **Signing & Capabilities**, and change `com.example.PixelBloom` to your own unique bundle identifier. Select the iPad and Run.

## Included

- Three detailed 64×64 scenes with 21–24 colors: a sunlit garden, a cabin at dusk, and a butterfly meadow.
- Eighteen original 16×16 pictures in a separate **Little pictures** section, retaining their saved progress.
- A sidebar with titles and progress only, so the finished artwork stays a surprise.
- Numbered colors with remaining-square counts and selected-color highlighting.
- Tap or drag to fill matching cells; incorrect colors never overwrite a square. Use one finger to paint, three fingers to pan, and pinch to zoom. Fast strokes fill intervening matching cells, including across tile boundaries.
- Pinch zoom, zoom buttons, and a scrollable board for precise coloring. Detailed scenes support 100–1000% zoom and an Overview button.
- Tiled canvas rendering and background saves to keep large pictures responsive.
- Hints that highlight and scroll to an unfinished cell.
- Per-picture progress automatically saved on this device.
- Completion feedback and a confirmed reset for each picture.
- Portrait, landscape, split-view navigation, and VoiceOver cell labels.

Choose a picture, select a numbered color below the canvas, then tap or drag across matching numbers. Detailed scenes start at 300% zoom. Pinch or use the zoom buttons for larger touch targets; Overview shows your whole canvas, with numbers hidden when cells are too small to read. Hints select another color if the current one is already finished. Progress remains when you switch pictures or relaunch the app. Deleting the app removes its local progress.

## Validation

The project builds with Xcode 27.2. The native XCTest suite runs on an iPad simulator and covers artwork integrity, tile coverage, single-cell and batch painting, stroke interpolation, palette counts, persistence, and compatibility with existing saved progress. Device gesture behavior, split-screen layout, and VoiceOver still need hands-on validation on an iPad.

`python3 verify_project.py` checks artwork dimensions, palette references, and Xcode project/scheme references. These checks were run in this workspace.

The included XCTest target covers matching-color enforcement, duplicate/invalid taps, progress calculation, saved-progress reload, reset isolation, and corrupt saved data. Run **Product → Test** (⌘U) in Xcode, or on a Mac:

```sh
xcodebuild -project PixelBloom.xcodeproj -scheme PixelBloom \
  -destination 'platform=iOS Simulator,name=iPad (10th generation)' test
```

Use an iPad simulator name installed on your Mac (`xcodebuild -showdestinations -scheme PixelBloom`). The XCTest suite passes on the installed iPad simulator.

## Source

- `Puzzle.swift`: artwork rows and palettes. A dot is an empty square; base-36 symbols (`1`–`9`, then `A`–`Z`) map to numbered colors. Artwork is parsed once when the library loads.
- `tools/generate_scenes.py`: dependency-free, deterministic authoring source for the detailed scenes. Run it to update the generated section of `Puzzle.swift`.
- `PaintStore.swift`: validated painting and local saved progress.
- `ContentView.swift`: gallery, coloring board, palettes, zoom, and hints.
- `PixelBloomApp.swift`: app entry point.
- `PixelBloomTests/`: native unit tests.

`make_project.py` regenerates the checked-in project and shared scheme without installing tools. Do not rerun it after customizing project settings unless you also update the generator.

This is an initial app implementation. App Store artwork/icons, signing, distribution, imported photos, and image export are not included.
