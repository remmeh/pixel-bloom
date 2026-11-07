import SwiftUI

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
    @Published private(set) var completed: [String: Set<Int>]
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

    func filled(in puzzle: Puzzle) -> Set<Int> { completed[puzzle.id] ?? [] }
    func progress(in puzzle: Puzzle) -> Double {
        guard !puzzle.paintable.isEmpty else { return 1 }
        return Double(filled(in: puzzle).count) / Double(puzzle.paintable.count)
    }
    func remaining(_ color: Int, in puzzle: Puzzle) -> Int {
        (puzzle.cellsByColor[color] ?? []).subtracting(filled(in: puzzle)).count
    }
    @discardableResult
    func paint(_ index: Int, color: Int, in puzzle: Puzzle) -> Bool {
        paint([index], color: color, in: puzzle) > 0
    }

    @discardableResult
    func paint(_ indices: [Int], color: Int, in puzzle: Puzzle) -> Int {
        guard color > 0 else { return 0 }
        let matching = Set(indices).intersection(puzzle.cellsByColor[color] ?? [])
        let additions = matching.subtracting(filled(in: puzzle))
        guard !additions.isEmpty else { return 0 }
        // Publish and save once per touch sample, even if it crosses many cells.
        completed[puzzle.id, default: []].formUnion(additions)
        save()
        return additions.count
    }
    func reset(_ puzzle: Puzzle) {
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
