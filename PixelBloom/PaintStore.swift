import SwiftUI

// UserDefaults supports concurrent access; all writes from this helper are serialized.
// Its references never change after initialization.
private final class ProgressPersistence: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String
    private let queue = DispatchQueue(label: "com.remmeh.PixelBloom.progress", qos: .utility)

    init(defaults: UserDefaults, key: String) {
        self.defaults = defaults
        self.key = key
    }

    func save(_ snapshot: [String: Set<Int>]) {
        queue.async { [self] in
            if let data = try? JSONEncoder().encode(snapshot) { defaults.set(data, forKey: key) }
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
        guard puzzle.cells.indices.contains(index), color > 0,
              puzzle.cells[index] == color, !filled(in: puzzle).contains(index) else { return false }
        completed[puzzle.id, default: []].insert(index)
        save()
        return true
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
