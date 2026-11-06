# Pixel Bloom for iPad

A native SwiftUI color-by-number app for iPadOS 17 and later. No third-party dependencies, account, server, or network access required.

## Try it on a Mac

1. Open `PixelBloom.xcodeproj` in Xcode 15 or later.
2. Select the **PixelBloom** scheme and an iPad simulator.
3. Press **Run** (⌘R).
4. For a physical iPad, connect it, choose your Apple development team under **Signing & Capabilities**, and change `com.example.PixelBloom` to your own unique bundle identifier. Select the iPad and Run.

## Included

- Three original 16×16 pictures: a flower, a cabin, and a butterfly.
- Numbered colors with remaining-square counts and selected-color highlighting.
- Tap-to-fill cells; incorrect colors never overwrite a square.
- Zoom buttons and a scrollable board for precise coloring.
- Hints that highlight and scroll to an unfinished cell.
- Per-picture progress automatically saved on this device.
- Completion feedback and a confirmed reset for each picture.
- Portrait, landscape, split-view navigation, and VoiceOver cell labels.

Choose a picture, select a numbered color below the canvas, then tap matching numbers. Use zoom for larger touch targets. Hints select another color if the current one is already finished. Progress remains when you switch pictures or relaunch the app. Deleting the app removes its local progress.

## Validation

The project was created in a Linux workspace without Swift, Xcode, or an iPad simulator. It has **not been compiled or tested on an Apple device**. Before shipping, build it in Xcode and check touch interaction, split-screen layout, VoiceOver, and persistence on an iPad.

`python3 verify_project.py` checks artwork dimensions, palette references, and Xcode project/scheme references. These checks were run in this workspace.

The included XCTest target covers matching-color enforcement, duplicate/invalid taps, progress calculation, saved-progress reload, reset isolation, and corrupt saved data. Run **Product → Test** (⌘U) in Xcode, or on a Mac:

```sh
xcodebuild -project PixelBloom.xcodeproj -scheme PixelBloom \
  -destination 'platform=iOS Simulator,name=iPad (10th generation)' test
```

Use an iPad simulator name installed on your Mac (`xcodebuild -showdestinations -scheme PixelBloom`). The XCTest suite has not been run here.

## Source

- `Puzzle.swift`: artwork rows and palettes. A dot is an empty square; digits map to palette numbers.
- `PaintStore.swift`: validated painting and local saved progress.
- `ContentView.swift`: gallery, coloring board, palettes, zoom, and hints.
- `PixelBloomApp.swift`: app entry point.
- `PixelBloomTests/`: native unit tests.

`make_project.py` regenerates the checked-in project and shared scheme without installing tools. Do not rerun it after customizing project settings unless you also update the generator.

This is an initial app implementation. App Store artwork/icons, signing, distribution, imported photos, and image export are not included.
