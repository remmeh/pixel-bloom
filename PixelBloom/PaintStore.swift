import SwiftUI

@MainActor
final class PaintStore: ObservableObject {
    @Published private(set) var completed: [String: Set<Int>]
    private let defaults: UserDefaults
    private let key = "pixelbloom.progress.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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
        puzzle.cells.indices.filter { puzzle.cells[$0] == color && !filled(in: puzzle).contains($0) }.count
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
        if let data = try? JSONEncoder().encode(completed) { defaults.set(data, forKey: key) }
    }
}
