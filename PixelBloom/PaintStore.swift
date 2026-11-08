import SwiftUI
import Observation

// UserDefaults supports concurrent access; all writes from this helper are serialized.
// Pending snapshots and worker state are protected by the lock.
private final class ProgressPersistence: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String
    private let queue = DispatchQueue(label: "com.remmeh.PixelBloom.progress", qos: .utility)
    private let lock = NSLock()
    private var pending: [String: Set<Int>]?
    private var isWriting = false

    init(defaults: UserDefaults, key: String) {
        self.defaults = defaults
        self.key = key
    }

    func save(_ snapshot: [String: Set<Int>]) {
        let shouldStart = lock.withLock {
            pending = snapshot
            guard !isWriting else { return false }
            isWriting = true
            return true
        }
        guard shouldStart else { return }
        queue.async { [self] in
            while let snapshot = takePending() {
                if let data = try? JSONEncoder().encode(snapshot) { defaults.set(data, forKey: key) }
            }
        }
    }

    private func takePending() -> [String: Set<Int>]? {
        lock.withLock {
            let snapshot = pending
            pending = nil
            if snapshot == nil { isWriting = false }
            return snapshot
        }
    }

    func flush() { queue.sync {} }
}

@MainActor
final class PaintStore: ObservableObject {
    private var completed: [String: Set<Int>]
    private var scenes: [String: PuzzleProgress] = [:]
    private let key = "pixelbloom.progress.v1"
    private let persistence: ProgressPersistence

    init(defaults: UserDefaults = .standard) {
        persistence = ProgressPersistence(defaults: defaults, key: key)
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode([String: Set<Int>].self, from: data) {
            completed = saved
        } else {
            completed = [:]
        }
        // Discard obsolete or invalid saved cells when artwork changes.
        completed = Dictionary(uniqueKeysWithValues: Puzzle.all.map { puzzle in
            (puzzle.id, (completed[puzzle.id] ?? []).intersection(puzzle.paintable))
        })
    }

    func scene(for puzzle: Puzzle) -> PuzzleProgress {
        if let scene = scenes[puzzle.id] { return scene }
        let scene = PuzzleProgress(puzzle: puzzle, filled: completed[puzzle.id] ?? [])
        scenes[puzzle.id] = scene
        return scene
    }

    func filled(in puzzle: Puzzle) -> Set<Int> { completed[puzzle.id] ?? [] }
    func filledCount(in puzzle: Puzzle) -> Int { scene(for: puzzle).filledCount }
    func progress(in puzzle: Puzzle) -> Double {
        scene(for: puzzle).fraction
    }
    func remaining(_ color: Int, in puzzle: Puzzle) -> Int {
        scene(for: puzzle).remainingByColor[color, default: 0]
    }
    @discardableResult
    func paint(_ index: Int, color: Int, in puzzle: Puzzle) -> Bool {
        paint([index], color: color, in: puzzle) > 0
    }

    @discardableResult
    func paint(_ indices: [Int], color: Int, in puzzle: Puzzle) -> Int {
        guard color > 0 else { return 0 }
        let scene = scene(for: puzzle)
        let added = scene.paint(indices, color: color)
        guard added > 0 else { return 0 }
        completed[puzzle.id] = scene.filled
        save()
        return added
    }
    func reset(_ puzzle: Puzzle) {
        scene(for: puzzle).reset()
        completed[puzzle.id] = []
        save()
    }
    private func save() {
        // Preserve write order and keep encoding and UserDefaults writes off the UI thread.
        persistence.save(completed)
    }

    // Drain pending writes when leaving the app, and before testing a fresh store.
    func flushPendingSaves() {
        persistence.flush()
    }
}

@MainActor
@Observable
final class PuzzleProgress {
    private let puzzle: Puzzle
    @ObservationIgnored private(set) var filled: Set<Int>
    @ObservationIgnored private var tiles: [Int: TileProgress] = [:]
    private(set) var filledCount: Int
    private(set) var remainingByColor: [Int: Int]

    init(puzzle: Puzzle, filled: Set<Int>) {
        self.puzzle = puzzle
        self.filled = filled
        filledCount = filled.count
        var counts = puzzle.cellsByColor.mapValues(\.count)
        for index in filled {
            counts[puzzle.cells[index], default: 0] -= 1
        }
        remainingByColor = counts
    }

    var fraction: Double {
        guard !puzzle.paintable.isEmpty else { return 1 }
        return Double(filledCount) / Double(puzzle.paintable.count)
    }

    func tile(_ tile: Puzzle.Tile) -> TileProgress {
        if let progress = tiles[tile.id] { return progress }
        let progress = TileProgress(filled: filled.intersection(tile.indices))
        tiles[tile.id] = progress
        return progress
    }

    fileprivate func paint(_ indices: [Int], color: Int) -> Int {
        var added = 0
        var changedTiles: [Int: [Int]] = [:]
        for index in indices where puzzle.cells.indices.contains(index) && puzzle.cells[index] == color {
            guard !filled.contains(index) else { continue }
            filled.insert(index)
            added += 1
            let tileID = puzzle.tileID(containing: index)
            if tiles[tileID] != nil { changedTiles[tileID, default: []].append(index) }
        }
        guard added > 0 else { return 0 }
        filledCount += added
        remainingByColor[color, default: 0] -= added
        for (id, cells) in changedTiles { tiles[id]?.filled.formUnion(cells) }
        return added
    }

    fileprivate func reset() {
        guard !filled.isEmpty else { return }
        filled = []
        filledCount = 0
        remainingByColor = puzzle.cellsByColor.mapValues(\.count)
        for tile in tiles.values where !tile.filled.isEmpty { tile.filled = [] }
    }
}

@MainActor
@Observable
final class TileProgress {
    fileprivate(set) var filled: Set<Int>

    fileprivate init(filled: Set<Int>) {
        self.filled = filled
    }
}
