import SwiftUI

struct PaintColor: Identifiable {
    let id: Int
    let name: String
    let hex: UInt32
    var color: Color {
        Color(red: Double((hex >> 16) & 255) / 255,
              green: Double((hex >> 8) & 255) / 255,
              blue: Double(hex & 255) / 255)
    }
}

struct Puzzle: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let rows: [String]
    let palette: [PaintColor]
    var width: Int { rows[0].count }
    var height: Int { rows.count }
    // A dot is empty canvas. Digits refer to the numbered palette.
    var cells: [Int] { rows.flatMap { $0.map { $0.wholeNumberValue ?? 0 } } }
    var paintable: Set<Int> { Set(cells.indices.filter { cells[$0] != 0 }) }

    static let all: [Puzzle] = [
        Puzzle(id: "bloom", title: "Little bloom", subtitle: "A little color, a little calm.", symbol: "camera.macro", rows: [
            "................", "......111.......", ".....12221......", "...111222111....",
            "..12223332221...", "..12234443221...", "..12234443221...", "...111333111....",
            ".....12221......", "......151.......", "...66..5..66....", "....6655666.....",
            ".....65566......", ".......5........", ".....77777......", "......777......."
        ], palette: [
            PaintColor(id: 1, name: "Rose", hex: 0xD85876), PaintColor(id: 2, name: "Petal", hex: 0xF5A8B8),
            PaintColor(id: 3, name: "Marigold", hex: 0xF0B84B), PaintColor(id: 4, name: "Sunshine", hex: 0xFFE5A0),
            PaintColor(id: 5, name: "Stem", hex: 0x3B7358), PaintColor(id: 6, name: "Leaf", hex: 0x87B589),
            PaintColor(id: 7, name: "Terracotta", hex: 0xBE795C)
        ]),
        Puzzle(id: "cabin", title: "Cozy cabin", subtitle: "Somewhere quiet to escape.", symbol: "house", rows: [
            "................", "..........11....", ".........1221...", "..........11....",
            "......3.........", ".....333........", "....34443.......", "...3444443......",
            "..344444443.....", "...5555555......", "...5665775..8...", "...5665775.888..",
            "...5555775..8...", "9999999999999999", ".99999999999999.", "................"
        ], palette: [
            PaintColor(id: 1, name: "Gold", hex: 0xEABA57), PaintColor(id: 2, name: "Light", hex: 0xFFE4A4),
            PaintColor(id: 3, name: "Roof edge", hex: 0x774E51), PaintColor(id: 4, name: "Roof", hex: 0xBC7370),
            PaintColor(id: 5, name: "Timber", hex: 0xD9AF83), PaintColor(id: 6, name: "Window", hex: 0xA7CDD1),
            PaintColor(id: 7, name: "Door", hex: 0x88654F), PaintColor(id: 8, name: "Pine", hex: 0x58816B),
            PaintColor(id: 9, name: "Meadow", hex: 0x9EB791)
        ]),
        Puzzle(id: "butterfly", title: "Garden wings", subtitle: "Make something lovely, one square at a time.", symbol: "sparkles", rows: [
            "................", "..11........11..", ".1221......1221.", ".12321.55.12321.",
            ".12332155123321.", "..123215512321..", "...1221551221...", "....11155111....",
            "....44455444....", "...4664554664...", "..467645546764..", "..466445544664..",
            "...444.55.444...", ".......55.......", "................", "................"
        ], palette: [
            PaintColor(id: 1, name: "Indigo", hex: 0x655783), PaintColor(id: 2, name: "Lavender", hex: 0xB3A0CF),
            PaintColor(id: 3, name: "Lilac", hex: 0xDED0EB), PaintColor(id: 4, name: "Deep rose", hex: 0xAF607F),
            PaintColor(id: 5, name: "Body", hex: 0x4B465C), PaintColor(id: 6, name: "Blush", hex: 0xE6A4B8),
            PaintColor(id: 7, name: "Cream", hex: 0xFFE2B9)
        ])
    ]
}
