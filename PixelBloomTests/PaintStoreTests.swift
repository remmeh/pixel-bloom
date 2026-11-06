import XCTest
@testable import PixelBloom

final class PaintStoreTests: XCTestCase {
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
    func testOnlyMatchingUnfilledCellsCanBePainted() {
        withDefaults { defaults in
            let store = PaintStore(defaults: defaults)
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
            let reloaded = PaintStore(defaults: defaults)
            XCTAssertEqual(reloaded.filled(in: Puzzle.all[0]).count, 1)
            reloaded.reset(Puzzle.all[0])
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
