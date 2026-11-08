import XCTest
import SwiftUI
import UIKit
import AVFoundation
import Observation
@testable import PixelBloom

final class PaintStoreTests: XCTestCase {
    func testSoundFeedbackSkipsInvalidPaintingAndPacesSwipes() {
        var feedback = ColoringSoundFeedback()
        XCTAssertNil(feedback.painted(added: 0, remaining: 10, interaction: .tap, now: 0))
        XCTAssertEqual(feedback.painted(added: 1, remaining: 9, interaction: .tap, now: 0), .pixel)
        XCTAssertNil(feedback.painted(added: 5, remaining: 4, interaction: .drag, now: 0.01))
        XCTAssertEqual(feedback.painted(added: 2, remaining: 2, interaction: .drag, now: 0.07), .swipe)
        // A completed color takes priority even within the swipe throttle interval.
        XCTAssertEqual(feedback.painted(added: 2, remaining: 0, interaction: .drag, now: 0.08), .colorCompleted)
        XCTAssertNil(feedback.painted(added: 0, remaining: 0, interaction: .drag, now: 0.09))
        XCTAssertNil(feedback.painted(added: 1, remaining: 8, interaction: .drag, now: 0.2))
        XCTAssertEqual(feedback.painted(added: 1, remaining: 7, interaction: .drag, now: 0.5), .swipe)
        XCTAssertNil(feedback.selected(from: 2, to: 2))
        XCTAssertEqual(feedback.selected(from: 2, to: 3), .colorSelected)
    }

    func testGeneratedSoundClipsDecodeAndAreDistinct() throws {
        var clips: Set<Data> = []
        for effect in ColoringSound.allCases {
            let data = ColoringSoundClip.wav(for: effect)
            XCTAssertEqual(String(data: data.prefix(4), encoding: .utf8), "RIFF")
            let player = try AVAudioPlayer(data: data)
            XCTAssertEqual(player.numberOfChannels, 1)
            XCTAssertGreaterThan(player.duration, 0.03)
            XCTAssertLessThan(player.duration, 0.6)
            XCTAssertTrue(data.dropFirst(44).contains(where: { $0 != 0 }))
            clips.insert(data)
        }
        XCTAssertEqual(clips.count, ColoringSound.allCases.count)
    }

    @MainActor
    func testCanvasRecognizersSeparatePaintingFromThreeFingerScrolling() {
        let scrollView = UIScrollView()
        let originalTouches = scrollView.panGestureRecognizer.minimumNumberOfTouches
        let input = CanvasTouchView()
        scrollView.addSubview(input)
        XCTAssertTrue(input.connectedScrollView === scrollView)
        XCTAssertEqual(scrollView.panGestureRecognizer.minimumNumberOfTouches, 3)
        XCTAssertEqual(input.paintPan.minimumNumberOfTouches, 1)
        XCTAssertEqual(input.paintPan.maximumNumberOfTouches, 1)
        XCTAssertEqual(input.paintTap.numberOfTouchesRequired, 1)
        input.removeFromSuperview()
        XCTAssertNil(input.connectedScrollView)
        XCTAssertEqual(scrollView.panGestureRecognizer.minimumNumberOfTouches, originalTouches)
        XCTAssertFalse(scrollView.gestureRecognizers?.contains(input.paintPan) ?? true)
    }

    @MainActor
    func testSecondFingerAndPinchDoNotContinuePaintStroke() {
        let input = CanvasTouchView()
        var segments: [(CGPoint, CGPoint)] = []
        input.onStroke = { start, end, _ in segments.append((start, end)) }
        let first = CGPoint(x: 5, y: 5)
        let second = CGPoint(x: 25, y: 5)
        input.handlePaintPan(state: .began, touches: 1, point: first, start: .zero)
        input.handlePaintPan(state: .changed, touches: 1, point: second, start: .zero)
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[1].0, first)
        input.handlePaintPan(state: .changed, touches: 2, point: second, start: .zero)
        input.handlePaintPan(state: .changed, touches: 1, point: second, start: .zero)
        input.handlePaintPan(state: .ended, touches: 0, point: second, start: .zero)
        XCTAssertEqual(segments.count, 2)
        input.handlePaintPan(state: .began, touches: 1, point: first, start: .zero)
        input.isPinching = true
        input.handlePaintPan(state: .changed, touches: 1, point: second, start: .zero)
        input.isPinching = false
        input.handlePaintPan(state: .ended, touches: 0, point: second, start: .zero)
        XCTAssertEqual(segments.count, 3)
        input.handlePaintPan(state: .began, touches: 1, point: first, start: first)
        input.handlePaintPan(state: .cancelled, touches: 0, point: first, start: first)
        input.handlePaintPan(state: .ended, touches: 0, point: second, start: first)
        XCTAssertEqual(segments.count, 4)
    }

    @MainActor
    func testTouchBridgeConnectsInsideSwiftUIBoard() async {
        let puzzle = Puzzle.detailed[0]
        let board = PixelBoard(puzzle: puzzle, scene: PuzzleProgress(puzzle: puzzle, filled: []), selectedColor: 1,
                               zoom: .constant(3), maximumZoom: 10, hint: .constant(nil), onPaint: { _, _ in })
        let host = UIHostingController(rootView: board)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 900, height: 600))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()
        let rendered = expectation(description: "SwiftUI inserts the touch bridge")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { rendered.fulfill() }
        await fulfillment(of: [rendered], timeout: 2)
        func findInput(_ view: UIView) -> CanvasTouchView? {
            if let input = view as? CanvasTouchView { return input }
            return view.subviews.lazy.compactMap { findInput($0) }.first
        }
        let input = findInput(host.view)
        XCTAssertNotNil(input)
        XCTAssertNotNil(input?.connectedScrollView)
        XCTAssertEqual(input?.connectedScrollView?.panGestureRecognizer.minimumNumberOfTouches, 3)
    }

    @MainActor
    private func withDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
        let suite = "PixelBloomTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    @MainActor
    func testArtworkHasRectangularRowsAndValidPaletteNumbers() {
        XCTAssertEqual(Set(Puzzle.all.map(\.id)).count, Puzzle.all.count)
        for puzzle in Puzzle.all {
            XCTAssertFalse(puzzle.paintable.isEmpty)
            XCTAssertTrue(puzzle.rows.allSatisfy { $0.count == puzzle.width })
            let numbers = Set(puzzle.palette.map(\.id))
            XCTAssertEqual(numbers.count, puzzle.palette.count)
            XCTAssertTrue(puzzle.cells.allSatisfy { $0 == 0 || numbers.contains($0) })
        }
    }

    @MainActor
    func testDetailedScenesAndTileCoverage() {
        XCTAssertEqual(Puzzle.detailed.count, 3)
        XCTAssertEqual(Puzzle.quick.count, 18)
        XCTAssertEqual(Puzzle.sanrio.count, 27)
        XCTAssertEqual(Puzzle.pusheen.id, "character-pusheen-64-v1")
        for puzzle in Puzzle.all {
            let indices = puzzle.tiles.flatMap(\.indices)
            XCTAssertEqual(indices.count, puzzle.cells.count)
            XCTAssertEqual(Set(indices), Set(puzzle.cells.indices))
            for tile in puzzle.tiles {
                XCTAssertLessThanOrEqual(tile.indices.count, 64)
                for index in tile.indices {
                    XCTAssertEqual(puzzle.tileID(containing: index), tile.id)
                }
            }
        }
        for puzzle in Puzzle.detailed + Puzzle.sanrio + [Puzzle.pusheen] {
            XCTAssertEqual(puzzle.width, 64)
            XCTAssertEqual(puzzle.height, 64)
            XCTAssertEqual(puzzle.paintable.count, 4096)
        }
        for puzzle in Puzzle.detailed { XCTAssertGreaterThan(puzzle.palette.count, 9) }
        let partial = Puzzle(id: "partial", title: "Test", subtitle: "", symbol: "",
                             rows: Array(repeating: "1111111111", count: 3),
                             palette: [PaintColor(id: 1, name: "Test", hex: 0)])
        XCTAssertEqual(partial.tiles.map(\.width), [8, 2])
        XCTAssertEqual(partial.tiles.flatMap(\.indices).count, 30)
        XCTAssertEqual(partial.tileID(containing: 29), 1)
    }

    @MainActor
    func testDetailedColorsSaveAlongsideExistingProgress() throws {
        try withDefaults { defaults in
            let original = Puzzle.quick[0]
            let originalCell = original.paintable.min()!
            defaults.set(try JSONEncoder().encode([original.id: Set([originalCell])]), forKey: "pixelbloom.progress.v1")
            let store = PaintStore(defaults: defaults)
            let detailed = Puzzle.detailed[0]
            let index = detailed.cells.firstIndex(where: { $0 > 9 })!
            XCTAssertTrue(store.paint(index, color: detailed.cells[index], in: detailed))
            store.flushPendingSaves()
            let reloaded = PaintStore(defaults: defaults)
            XCTAssertEqual(reloaded.filled(in: original), [originalCell])
            XCTAssertEqual(reloaded.filled(in: detailed), [index])
        }
    }

    @MainActor
    func testPaintingNotifiesOnlyTheChangedSceneAndTile() {
        withDefaults { defaults in
            let store = PaintStore(defaults: defaults)
            defer { store.flushPendingSaves() }
            let puzzle = Puzzle.detailed[0]
            let scene = store.scene(for: puzzle)
            let changed = scene.tile(puzzle.tiles[0])
            let unchanged = scene.tile(puzzle.tiles[1])
            let otherScene = store.scene(for: Puzzle.detailed[1])
            let updated = expectation(description: "The painted tile publishes its new cells")
            withObservationTracking {
                _ = changed.filled
            } onChange: {
                updated.fulfill()
            }
            withObservationTracking {
                _ = unchanged.filled
                _ = otherScene.fraction
            } onChange: {
                XCTFail("Painting invalidated an unrelated tile or scene")
            }
            let index = puzzle.tiles[0].indices.first { puzzle.cells[$0] > 0 }!
            XCTAssertTrue(store.paint(index, color: puzzle.cells[index], in: puzzle))
            wait(for: [updated], timeout: 0)
            XCTAssertEqual(changed.filled, [index])
            store.reset(puzzle)
            XCTAssertTrue(changed.filled.isEmpty)
        }
    }

    @MainActor
    func testStrokeCrossesTilesAndFillsOnlyMatchingCellsOnce() {
        withDefaults { defaults in
            let puzzle = Puzzle(id: "stroke", title: "Test", subtitle: "", symbol: "",
                                rows: ["111111112211111111", "111111112211111111"],
                                palette: [PaintColor(id: 1, name: "One", hex: 0),
                                          PaintColor(id: 2, name: "Two", hex: 0)])
            let indices = puzzle.strokeIndices(from: CGPoint(x: 5, y: 5), to: CGPoint(x: 175, y: 5), unit: 10)
            XCTAssertEqual(indices, Array(0..<18))
            let store = PaintStore(defaults: defaults)
            defer { store.flushPendingSaves() }
            XCTAssertEqual(store.paint(indices + [-1, 9999, 0], color: 1, in: puzzle), 16)
            XCTAssertEqual(store.filled(in: puzzle), Set(indices).subtracting([8, 9]))
            XCTAssertEqual(store.paint(indices, color: 1, in: puzzle), 0)
            XCTAssertEqual(store.paint(indices, color: 0, in: puzzle), 0)
            XCTAssertEqual(store.paint(indices, color: 2, in: puzzle), 2)
            XCTAssertEqual(store.filled(in: puzzle), Set(0..<18))
        }
    }

    @MainActor
    func testStrokeSamplingHandlesDiagonalReverseAndCanvasEdges() {
        let puzzle = Puzzle(id: "sampling", title: "Test", subtitle: "", symbol: "",
                            rows: Array(repeating: String(repeating: "1", count: 18), count: 18),
                            palette: [PaintColor(id: 1, name: "One", hex: 0)])
        let diagonal = (0..<18).map { $0 * 18 + $0 }
        XCTAssertEqual(puzzle.strokeIndices(from: CGPoint(x: 5, y: 5), to: CGPoint(x: 175, y: 175), unit: 10), diagonal)
        XCTAssertEqual(puzzle.strokeIndices(from: CGPoint(x: 175, y: 175), to: CGPoint(x: 5, y: 5), unit: 10), diagonal.reversed())
        XCTAssertEqual(puzzle.strokeIndices(from: CGPoint(x: -20, y: 5), to: CGPoint(x: 25, y: 5), unit: 10), [0, 1, 2])
        XCTAssertTrue(puzzle.strokeIndices(from: CGPoint(x: -1, y: -1), to: CGPoint(x: -1, y: -1), unit: 10).isEmpty)
        XCTAssertTrue(puzzle.strokeIndices(from: CGPoint(x: 180, y: 0), to: CGPoint(x: 180, y: 0), unit: 10).isEmpty)
        XCTAssertTrue(puzzle.strokeIndices(from: .zero, to: .zero, unit: 0).isEmpty)
    }

    @MainActor
    func testBatchStrokeProgressSurvivesRelaunch() {
        withDefaults { defaults in
            let store = PaintStore(defaults: defaults)
            let puzzle = Puzzle.detailed[0]
            let color = puzzle.cells[0]
            let indices = Array(puzzle.cellsByColor[color]!.sorted().prefix(200))
            XCTAssertEqual(store.paint(indices, color: color, in: puzzle), indices.count)
            store.flushPendingSaves()
            let reloaded = PaintStore(defaults: defaults)
            XCTAssertEqual(reloaded.filled(in: puzzle), Set(indices))
            XCTAssertEqual(reloaded.remaining(color, in: puzzle), puzzle.cellsByColor[color]!.count - indices.count)
        }
    }

    @MainActor
    func testOnlyMatchingUnfilledCellsCanBePainted() {
        withDefaults { defaults in
            let store = PaintStore(defaults: defaults)
            defer { store.flushPendingSaves() }
            let puzzle = Puzzle.all[0]
            let index = puzzle.cells.firstIndex(of: 1)!
            XCTAssertFalse(store.paint(index, color: 2, in: puzzle))
            XCTAssertFalse(store.paint(-1, color: 1, in: puzzle))
            XCTAssertFalse(store.paint(puzzle.cells.count, color: 1, in: puzzle))
            XCTAssertFalse(store.paint(0, color: 0, in: puzzle))
            XCTAssertTrue(store.paint(index, color: 1, in: puzzle))
            XCTAssertFalse(store.paint(index, color: 1, in: puzzle))
            XCTAssertEqual(store.filled(in: puzzle), [index])
        }
    }

    @MainActor
    func testProgressSurvivesRelaunchAndResetIsIsolated() {
        withDefaults { defaults in
            let store = PaintStore(defaults: defaults)
            for puzzle in Puzzle.all.prefix(2) {
                let index = puzzle.paintable.min()!
                store.paint(index, color: puzzle.cells[index], in: puzzle)
            }
            store.flushPendingSaves()
            let reloaded = PaintStore(defaults: defaults)
            XCTAssertEqual(reloaded.filled(in: Puzzle.all[0]).count, 1)
            reloaded.reset(Puzzle.all[0])
            reloaded.flushPendingSaves()
            let afterReset = PaintStore(defaults: defaults)
            XCTAssertTrue(afterReset.filled(in: Puzzle.all[0]).isEmpty)
            XCTAssertEqual(afterReset.filled(in: Puzzle.all[1]).count, 1)
        }
    }

    @MainActor
    func testCompletionCountsOnlyPaintableSquares() {
        withDefaults { defaults in
            let store = PaintStore(defaults: defaults)
            let puzzle = Puzzle.all[0]
            for index in puzzle.paintable { store.paint(index, color: puzzle.cells[index], in: puzzle) }
            XCTAssertEqual(store.progress(in: puzzle), 1)
            for color in puzzle.palette { XCTAssertEqual(store.remaining(color.id, in: puzzle), 0) }
            store.flushPendingSaves()
        }
    }

    @MainActor
    func testColorCountsFollowPaintingAndReset() {
        withDefaults { defaults in
            let store = PaintStore(defaults: defaults)
            let puzzle = Puzzle.all[0]
            for color in puzzle.palette {
                let indices = puzzle.cells.indices.filter { puzzle.cells[$0] == color.id }
                XCTAssertEqual(puzzle.cellsByColor[color.id], Set(indices))
                XCTAssertEqual(store.remaining(color.id, in: puzzle), indices.count)
                XCTAssertTrue(store.paint(indices[0], color: color.id, in: puzzle))
                XCTAssertEqual(store.remaining(color.id, in: puzzle), indices.count - 1)
            }
            store.reset(puzzle)
            for color in puzzle.palette {
                XCTAssertEqual(store.remaining(color.id, in: puzzle), puzzle.cellsByColor[color.id]?.count)
            }
            store.flushPendingSaves()
            XCTAssertTrue(PaintStore(defaults: defaults).filled(in: puzzle).isEmpty)
        }
    }

    @MainActor
    func testCorruptAndOutOfBoundsSavedDataIsHandled() throws {
        try withDefaults { defaults in
            defaults.set(Data("broken".utf8), forKey: "pixelbloom.progress.v1")
            XCTAssertEqual(PaintStore(defaults: defaults).progress(in: Puzzle.all[0]), 0)
            let puzzle = Puzzle.all[0]
            let valid = puzzle.paintable.min()!
            defaults.set(try JSONEncoder().encode([puzzle.id: Set([-1, 0, valid, 9999])]), forKey: "pixelbloom.progress.v1")
            XCTAssertEqual(PaintStore(defaults: defaults).filled(in: puzzle), [valid])
        }
    }
}
