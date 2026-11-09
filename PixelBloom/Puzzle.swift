import SwiftUI

struct PaintColor: Identifiable, Equatable {
    let id: Int
    let name: String
    let hex: UInt32
    var color: Color {
        Color(red: Double((hex >> 16) & 255) / 255,
              green: Double((hex >> 8) & 255) / 255,
              blue: Double(hex & 255) / 255)
    }
}

struct Puzzle: Identifiable, Equatable {
    struct Tile: Identifiable, Equatable {
        let id: Int
        let column: Int
        let row: Int
        let width: Int
        let height: Int
        let indices: [Int]
    }

    static let tileSize = 8
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let rows: [String]
    let palette: [PaintColor]
    let width: Int
    let height: Int
    let cells: [Int]
    let paintable: Set<Int>
    let cellsByColor: [Int: Set<Int>]
    let colorsByNumber: [Int: PaintColor]
    let tiles: [Tile]
    var tileColumns: Int { (width + Self.tileSize - 1) / Self.tileSize }

    func tileID(containing index: Int) -> Int {
        (index / width / Self.tileSize) * tileColumns + (index % width / Self.tileSize)
    }

    // Sample at half-cell intervals so fast strokes also cover intervening cells.
    // Coordinates belong to the grid itself, before its surrounding padding.
    func strokeIndices(from start: CGPoint, to end: CGPoint, unit: CGFloat, contactRadius: CGFloat = 0) -> [Int] {
        guard unit.isFinite, unit > 0, start.x.isFinite, start.y.isFinite,
              end.x.isFinite, end.y.isFinite else { return [] }
        // Ignore light contact and cap the extra reach to two cells at any zoom.
        let radius = contactRadius.isFinite ? min(2, max(0, contactRadius - 12) * 1.25 / unit) : 0
        let distance = max(abs(end.x - start.x), abs(end.y - start.y))
        let steps = max(1, Int(ceil(distance / unit * 2)))
        var visited: Set<Int> = []
        var result: [Int] = []
        for step in 0...steps {
            let fraction = CGFloat(step) / CGFloat(steps)
            let x = (start.x + (end.x - start.x) * fraction) / unit
            let y = (start.y + (end.y - start.y) * fraction) / unit
            guard x + radius >= 0, y + radius >= 0,
                  x - radius < CGFloat(width), y - radius < CGFloat(height) else { continue }
            if radius == 0 {
                let index = Int(y) * width + Int(x)
                if cells[index] > 0, visited.insert(index).inserted { result.append(index) }
                continue
            }
            let columns = Int(max(0, x - radius))...Int(min(CGFloat(width - 1), x + radius))
            let rows = Int(max(0, y - radius))...Int(min(CGFloat(height - 1), y + radius))
            for row in rows {
                for column in columns {
                    let index = row * width + column
                    guard cells[index] > 0 else { continue }
                    // Distance to the cell rectangle keeps the footprint round.
                    let dx = max(0, CGFloat(column) - x, x - CGFloat(column + 1))
                    let dy = max(0, CGFloat(row) - y, y - CGFloat(row + 1))
                    if dx * dx + dy * dy <= radius * radius, visited.insert(index).inserted {
                        result.append(index)
                    }
                }
            }
        }
        return result
    }

    init(id: String, title: String, subtitle: String, symbol: String, rows: [String], palette: [PaintColor]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.rows = rows
        self.palette = palette
        width = rows.first?.count ?? 0
        height = rows.count
        // Parse immutable artwork once, rather than on every view update.
        // Base-36 symbols allow palettes with more than nine numbered colors.
        let parsed = rows.flatMap { $0.map { Int(String($0), radix: 36) ?? 0 } }
        cells = parsed
        paintable = Set(parsed.indices.filter { parsed[$0] > 0 })
        cellsByColor = Dictionary(grouping: parsed.indices.filter { parsed[$0] > 0 }, by: { parsed[$0] })
            .mapValues { Set($0) }
        colorsByNumber = Dictionary(uniqueKeysWithValues: palette.map { ($0.id, $0) })
        let columns = rows.first?.count ?? 0
        var builtTiles: [Tile] = []
        for y in stride(from: 0, to: rows.count, by: Self.tileSize) {
            for x in stride(from: 0, to: columns, by: Self.tileSize) {
                let tileWidth = min(Self.tileSize, columns - x)
                let tileHeight = min(Self.tileSize, rows.count - y)
                let indices = (y..<(y + tileHeight)).flatMap { row in
                    (x..<(x + tileWidth)).map { row * columns + $0 }
                }
                builtTiles.append(Tile(id: builtTiles.count, column: x, row: y,
                                       width: tileWidth, height: tileHeight, indices: indices))
            }
        }
        tiles = builtTiles
    }

    static let all: [Puzzle] = detailed + sanrio + [pusheen] + quick

    static let quick: [Puzzle] = [
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
        ]),
        Puzzle(id: "kitten", title: "Peachy kitten", subtitle: "A tiny friend with a big purr.", symbol: "cat", rows: [
            "................", "................", "...11......11...", "...121....121...",
            "...1221111221...", "...1222222221...", "...1222222221...", "...1223223221...",
            "...1222442221...", "...1224244221...", "....12222221....", ".....155551.....",
            ".....155551.....", "....11555511....", "................", "................"
        ], palette: [
            PaintColor(id: 1, name: "Outline", hex: 0xA8674F),
            PaintColor(id: 2, name: "Peach", hex: 0xF4BF98),
            PaintColor(id: 3, name: "Eyes", hex: 0x3C3846),
            PaintColor(id: 4, name: "Blush", hex: 0xE98295),
            PaintColor(id: 5, name: "Cream", hex: 0xFFE7C7)
        ]),
        Puzzle(id: "bunny", title: "Bunny wishes", subtitle: "Soft ears and sunny thoughts.", symbol: "hare", rows: [
            "................", "................", "....11....11....", "....121..121....",
            "....121..121....", "....121..121....", "....12211221....", "...1222222221...",
            "...1223223221...", "...1222442221...", "...1224244221...", "....12222221....",
            ".....155551.....", "....11555511....", "................", "................"
        ], palette: [
            PaintColor(id: 1, name: "Outline", hex: 0xB191B5),
            PaintColor(id: 2, name: "Fur", hex: 0xEADAEF),
            PaintColor(id: 3, name: "Eyes", hex: 0x4E415C),
            PaintColor(id: 4, name: "Rose", hex: 0xE995B5),
            PaintColor(id: 5, name: "Tummy", hex: 0xFFF0DF)
        ]),
        Puzzle(id: "bear", title: "Honey bear", subtitle: "A bear-sized helping of cozy.", symbol: "pawprint", rows: [
            "................", "................", "....111..111....", "....121..121....",
            "...1122112211...", "...1222222221...", "...1223223221...", "...1224442221...",
            "...1224342221...", "....12222221....", ".....155551.....", "....12555521....",
            "...1125555211...", "....111..111....", "................", "................"
        ], palette: [
            PaintColor(id: 1, name: "Cocoa", hex: 0x865B48),
            PaintColor(id: 2, name: "Honey", hex: 0xD8A56C),
            PaintColor(id: 3, name: "Eyes", hex: 0x3D3338),
            PaintColor(id: 4, name: "Muzzle", hex: 0xF5D8AC),
            PaintColor(id: 5, name: "Sweater", hex: 0xA4BEB1)
        ]),
        Puzzle(id: "fox", title: "Woodland fox", subtitle: "A little woodland magic.", symbol: "pawprint", rows: [
            "................", "...11......11...", "...121....121...", "...1221..1221...",
            "...1222112221...", "...1222222221...", "...1223223221...", "...1244224421...",
            "....14433441....", ".....144441.....", "......1111......", ".....12221.11...",
            ".....12221121...", ".....14412221...", "......111111....", "................"
        ], palette: [
            PaintColor(id: 1, name: "Outline", hex: 0x955039),
            PaintColor(id: 2, name: "Ginger", hex: 0xEF975B),
            PaintColor(id: 3, name: "Nose", hex: 0x3E3540),
            PaintColor(id: 4, name: "Cream", hex: 0xFFE8C9)
        ]),
        Puzzle(id: "panda", title: "Pocket panda", subtitle: "A gentle pal in black and cream.", symbol: "pawprint", rows: [
            "................", "....111..111....", "....111..111....", "...1122222211...",
            "...1222222221...", "...1211221121...", "...1213223121...", "...1222442221...",
            "....12211221....", ".....122221.....", "....11555511....", "...1115555111...",
            "....11555511....", ".....11..11.....", "................", "................"
        ], palette: [
            PaintColor(id: 1, name: "Charcoal", hex: 0x494554),
            PaintColor(id: 2, name: "Cream", hex: 0xFFF0D8),
            PaintColor(id: 3, name: "Glint", hex: 0xD0DFE7),
            PaintColor(id: 4, name: "Cheeks", hex: 0xF0AEBA),
            PaintColor(id: 5, name: "Bamboo", hex: 0x92B89A)
        ]),
        Puzzle(id: "frog", title: "Lily-pad pal", subtitle: "Hop into a happy little break.", symbol: "leaf", rows: [
            "................", "....111..111....", "...1222112221...", "...1232112321...",
            "...1222222221...", "...1222222221...", "...1242112421...", "....12211221....",
            ".....122221.....", "....12222221....", "...1222552221...", "...1122552211...",
            ".....111111.....", "..666666666666..", "...6666666666...", "................"
        ], palette: [
            PaintColor(id: 1, name: "Moss", hex: 0x4F8255),
            PaintColor(id: 2, name: "Lime", hex: 0xABD07E),
            PaintColor(id: 3, name: "Eyes", hex: 0x34423E),
            PaintColor(id: 4, name: "Cheeks", hex: 0xF2A5AA),
            PaintColor(id: 5, name: "Tummy", hex: 0xDCE7A2),
            PaintColor(id: 6, name: "Lily pad", hex: 0x78AD94)
        ]),
        Puzzle(id: "penguin", title: "Snow-day penguin", subtitle: "A small waddle of joy.", symbol: "snowflake", rows: [
            "................", "......1111......", ".....122221.....", "....12222221....",
            "...1223333221...", "...1234334321...", "...1233553321...", "...1233553321...",
            "...1233333321...", "...1233333321...", "....13333331....", "....13333331....",
            ".....111111.....", ".....55..55.....", "....555..555....", "................"
        ], palette: [
            PaintColor(id: 1, name: "Outline", hex: 0x39485D),
            PaintColor(id: 2, name: "Blue", hex: 0x718AA6),
            PaintColor(id: 3, name: "Snow", hex: 0xE8F0E9),
            PaintColor(id: 4, name: "Eyes", hex: 0x30313F),
            PaintColor(id: 5, name: "Apricot", hex: 0xEFB068)
        ]),
        Puzzle(id: "whale", title: "Bubble whale", subtitle: "Float along at your own pace.", symbol: "drop", rows: [
            "................", "......22........", ".....2..2.......", "......2.........",
            ".....11111......", "....1222221.....", "..1122222221....", "..12222222221...",
            "..12223222221...", "..122242222211..", "..122222222122..", "..125555552122..",
            "...15555551111..", "....111111......", "................", "................"
        ], palette: [
            PaintColor(id: 1, name: "Ocean", hex: 0x507AA5),
            PaintColor(id: 2, name: "Sky", hex: 0x9CCDE1),
            PaintColor(id: 3, name: "Eye", hex: 0x35405B),
            PaintColor(id: 4, name: "Cheek", hex: 0xEDA8BF),
            PaintColor(id: 5, name: "Foam", hex: 0xE2F1E8)
        ]),
        Puzzle(id: "mushroom", title: "Mushroom cottage", subtitle: "A fairy-sized place to rest.", symbol: "house", rows: [
            "................", "......1111......", ".....122221.....", "....12233221....",
            "...1222332221...", "..122222222221..", "..122332223321..", "..122332223321..",
            "...1111111111...", ".....444444.....", ".....455554.....", ".....456654.....",
            ".....456654.....", ".....444444.....", "...7777777777...", "................"
        ], palette: [
            PaintColor(id: 1, name: "Berry", hex: 0xB75464),
            PaintColor(id: 2, name: "Cap", hex: 0xED91A1),
            PaintColor(id: 3, name: "Spots", hex: 0xFFEAD3),
            PaintColor(id: 4, name: "Stem", hex: 0xEAC9A4),
            PaintColor(id: 5, name: "Door", hex: 0xAA806E),
            PaintColor(id: 6, name: "Window", hex: 0xB5DADD),
            PaintColor(id: 7, name: "Grass", hex: 0x90B68A)
        ]),
        Puzzle(id: "strawberry", title: "Sweet strawberry", subtitle: "A berry sweet little moment.", symbol: "heart", rows: [
            "................", ".......11.......", ".....112211.....", "......1221......",
            ".....113311.....", "....13333331....", "...1334334331...", "...1333333331...",
            "...1343343341...", "...1333333331...", "....13343331....", "....13333331....",
            ".....134331.....", "......1331......", ".......11.......", "................"
        ], palette: [
            PaintColor(id: 1, name: "Outline", hex: 0xAA4E5C),
            PaintColor(id: 2, name: "Leaf", hex: 0x88AD6E),
            PaintColor(id: 3, name: "Berry", hex: 0xEF8594),
            PaintColor(id: 4, name: "Seeds", hex: 0xFFE5A2)
        ]),
        Puzzle(id: "cupcake", title: "Cupcake party", subtitle: "Sprinkle a little happiness.", symbol: "birthday.cake", rows: [
            "................", ".......11.......", "......1221......", ".......11.......",
            "......3333......", ".....344443.....", "....34454443....", "...3454444543...",
            "..344445444443..", "...3333333333...", "...6676676676...", "...6676676676...",
            "....67667676....", "....67667676....", ".....666666.....", "................"
        ], palette: [
            PaintColor(id: 1, name: "Cherry edge", hex: 0xB35270),
            PaintColor(id: 2, name: "Cherry", hex: 0xF18BA1),
            PaintColor(id: 3, name: "Frosting edge", hex: 0xC58DB6),
            PaintColor(id: 4, name: "Frosting", hex: 0xEFC5DB),
            PaintColor(id: 5, name: "Sprinkles", hex: 0xA3CDBA),
            PaintColor(id: 6, name: "Wrapper", hex: 0xBB916F),
            PaintColor(id: 7, name: "Gold", hex: 0xF5D597)
        ]),
        Puzzle(id: "icecream", title: "Scoops of joy", subtitle: "A tiny treat, just for you.", symbol: "snowflake", rows: [
            "......1111......", ".....122221.....", "....12232221....", "....12222221....",
            ".....111111.....", ".....444444.....", "....45555554....", "...4553555554...",
            "...4555555554...", "....44444444....", ".....667766.....", ".....676676.....",
            "......6776......", "......6776......", ".......66.......", "................"
        ], palette: [
            PaintColor(id: 1, name: "Berry edge", hex: 0xBD719B),
            PaintColor(id: 2, name: "Berry cream", hex: 0xEDB4D0),
            PaintColor(id: 3, name: "Shine", hex: 0xFFF0DA),
            PaintColor(id: 4, name: "Mint edge", hex: 0x74A993),
            PaintColor(id: 5, name: "Mint", hex: 0xB8DCC2),
            PaintColor(id: 6, name: "Cone edge", hex: 0xB4865D),
            PaintColor(id: 7, name: "Waffle", hex: 0xEDC58B)
        ]),
        Puzzle(id: "cactus", title: "Cactus cuddle", subtitle: "Growing at your own pace.", symbol: "leaf", rows: [
            ".......44.......", "......4554......", ".......44.......", "......1111......",
            ".....122221.....", "..11.123321.11..", "..121123321121..", "..121123321121..",
            "..122223322221..", "...1112332111...", ".....123321.....", ".....111111.....",
            "....66666666....", ".....677776.....", ".....677776.....", "......6666......"
        ], palette: [
            PaintColor(id: 1, name: "Forest", hex: 0x4D8068),
            PaintColor(id: 2, name: "Sage", hex: 0x96BD8C),
            PaintColor(id: 3, name: "Highlight", hex: 0xC4D7A0),
            PaintColor(id: 4, name: "Flower edge", hex: 0xCD7196),
            PaintColor(id: 5, name: "Flower", hex: 0xF3BCD0),
            PaintColor(id: 6, name: "Pot edge", hex: 0xB77760),
            PaintColor(id: 7, name: "Clay", hex: 0xE4A27B)
        ]),
        Puzzle(id: "bee", title: "Bumble buddy", subtitle: "Busy making sunny memories.", symbol: "sparkles", rows: [
            "................", "....11....11....", ".....1....1.....", "....222..222....",
            "...2332112332...", "...2332112332...", "....22144122....", ".....144441.....",
            "....14411441....", "....14411441....", "....14511451....", ".....144441.....",
            "......1111......", ".......11.......", "................", "................"
        ], palette: [
            PaintColor(id: 1, name: "Cocoa", hex: 0x5A4850),
            PaintColor(id: 2, name: "Wing edge", hex: 0x92BFCB),
            PaintColor(id: 3, name: "Wings", hex: 0xD4EBE7),
            PaintColor(id: 4, name: "Honey", hex: 0xF3CD6F),
            PaintColor(id: 5, name: "Cheeks", hex: 0xEC9E9D)
        ]),
        Puzzle(id: "star", title: "Sleepy star", subtitle: "A pocketful of starlight.", symbol: "star", rows: [
            "................", ".......1........", "......121.......", "......121.......",
            ".....12221......", ".1111122211111..", ".1222222222221..", "..12232232221...",
            "...122444221....", "....1222221.....", "...122222221....", "...122111221....",
            "..1221...1221...", "..111.....111...", "................", "................"
        ], palette: [
            PaintColor(id: 1, name: "Gold", hex: 0xCF9E48),
            PaintColor(id: 2, name: "Starlight", hex: 0xFFE09A),
            PaintColor(id: 3, name: "Eyes", hex: 0x62505B),
            PaintColor(id: 4, name: "Blush", hex: 0xEDAA9D)
        ])
    ]
}

// BEGIN GENERATED SCENES — tools/generate_scenes.py
extension Puzzle {
    static let detailed: [Puzzle] = [
        Puzzle(id: "garden-64-v1", title: "Sunlit garden", subtitle: "Petals, terracotta, and a winding garden path.", symbol: "camera.macro", rows: [
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111111111111111111111111111111111111111111611111111111111",
            "1111111111111111111111111111111111111111111111666666611111111111",
            "1111111111111111131111111111111111111111111116666666661111111111",
            "1111111111111333333333111111111111111111111166666666666111111111",
            "1111111111133333333333311111111111111111111166666666666111111111",
            "1111133333333333333333111111111111111111111166666666666111111111",
            "1111333333333333333BBBB1BBBB111111111111111666666666666611111111",
            "111113333333333333BCCCBBCCCBB11111111111111166666666666111111111",
            "11111111111311111BCCCCBCCCCCBB1111111111111166666666666111111111",
            "11111111111111111BCCCCBCCCCCBB1111111111111166666666666111111111",
            "22222222222222222BCCCCBCCCCCBB2222222222222226666666662222222222",
            "2222222222222222CBBCCCFFFCCBBBB222222322222222666666622222222222",
            "222222222222222BCCBBBFFFFFBBBCBB33333333333322222622222222222222",
            "222222222222222CCCCBFF6FFFFBCCCB33333333333333222222222222222222",
            "222222222222222CCCCCFFFFFFFCCCCB33333333333322222222222222222222",
            "222222222222222BCCCCFFFFFFFBCCBB22222322222222222222222222222222",
            "222222222222222BBCCBBFFFFFCCBBBB22222222222222222222222222222222",
            "2222222222222222BBBBBCFFFCCCBBBACCAACCAA222222222222222222222222",
            "222222222DEEDDEEDDBBCCCBBCCCBB2CCCCCCCCA444422O222E2222222222222",
            "222222222EEEEEEEEDCCCCCBBCCCBBACCCACCCCAA4444OOO4EEE222222222222",
            "22222222DEEEDEEEEDDCCCBBBCCBBBACCCACCCCAA4444OOOLEEE442222222222",
            "22222244DEEEDEEEEDDBBBBBBBBBBCCAAA666AAACA44OOOOLEEEE44444422222",
            "2222444EEDDDFFFDDDEDBBB7BBBB4CCAA66666AACA444OOOLEEE444444444442",
            "2244444EEDDF6FFFDDED44474444ACCCC66666CCCAA44OOOLEEE444444444442",
            "444444DEEEEFFFFFEEEDD44744448ACCA66666AAAA4444O4L4E4444444444442",
            "4444444DEEDFFFFFDDDD894DD4DD9AAAAA666CCAAA4444455555544444444442",
            "4444444DDDDDFFFEEDDD98EEEEEED8AAACCAACCAA44455555555555544444441",
            "44444444DDDEEDDEEDD888EEEEEED4ACCCCAACCAA45555555555555555554441",
            "44444445DEEEEDDEEDD88EEEEEEEDD4AAAAAAAAA555555555555555555555551",
            "444455555DDDDDDDDD88EEDD6FFDDEDAAAAAAAAA555555555555555555555551",
            "55555CCCCADDDDDDDD55DEEDFFFEEDD444888555555555555555855555555551",
            "55558CCCCA5855585575DDDDFFFEDDD88888555MMMMM55555555855555555551",
            "5585CA66AAA8885585575DDDEDEEDD888885555MMMMMM5558558585555555551",
            "5588CC666CA88888855755EEEDEED8888885555MMMMMMM558855555555555581",
            "5855AAA6CAA78888885575DDDDDDD9988855555MMMMMMM585585555555555581",
            "55555CCACA8588889999755DD8DD88899955555MMMMMMMMH558558555555H851",
            "55555AAAAA58999988885757888885855555555MMMMMMMHHHG855585555HHHG1",
            "585585555555558888888577755885585555555MMMMMMMMH758555855555H751",
            "8555855555555LLLLLLL88777LLLLLLLLL55555MMMMNNNHHHG585555555HHHG1",
            "85585555555LLLLLLLLLLL77LLLLLLLLLLLL55MMMMMMMMMH755H55555585H751",
            "555555555JKKKLLLLLLLLLLLLLLLLLLLLLKKKJMMMMMMMMHHHGHHHG55558HHHG1",
            "555555555JJJJJJJJJJJJJJLJJJJJJJJJJJJJJMMMMMMMMMH7M5H75585558H751",
            "555555555JJJJJJJJJJJJJJJJJJJJJJJJJJJJJMMMMMMMMMM7MHHHG5585558751",
            "555555555JJJJJJJJJJJJJJJJJJJJJJJJJJJJJMMMMMMMMMM7MMH7555H5555751",
            "85555855555IIJJJKKKKKJJJJJJJJJJJJIII85MMMMMMMMMM7MHHHG5HHHG55751",
            "855585555555IJJJKKKKKJJJJJJJJJJJJII585MMMMMMMMMM7MMH7555H7855751",
            "585335555555IIJJKKKKKJJJJJJJJJJJJII55MMMMMMMMMMNNNNN755HHHG55551",
            "5556EE555555IIJJKKKKKJJJJJJJJJJJIII55MMMMMMMMMMMMMMM7M55H7555551",
            "555EFE5555555IJJKKKKKJJJJJJJJJJJIII55MMMMMMMMMMMMMMM7M5HHHG55551",
            "555EEE5555555IIJJKKKKKJJJJJJJJJJII555MMMMMMMMMMMMMMM7MM5H7555851",
            "5555555555555IIJJKKKKKJJJJJJJJJJII855MMMMMMMMMMMMMMMMMMM57555581",
            "55555555555585IJJKKKKKJJJJJJJJJII3355MMMMMMMMMMMMMMMMMMM57555581",
            "55555555555585IIJKKKKKJJJJJJJJJII6EE5MMMMMMMMMMMMMMMMMMMM7555551",
            "55555533555555IIJKKKKKJJJJJJJJJIIEFEMMMMMMMMMMMMMMMMMMMMM7335551",
            "5555556EE555585IIIIIIIIIIIIIIIIIIEEEMMMMMMMMNNNNNMMMMMMMMM6EE551",
            "555555EFE577777IIIIIIIIIIIIIIIIII7777MMMMMMMMMMMMMMMMMMMMMEFE551",
            "555555EEE7777777777777777777777777777777MMMMMMMMMMMMMMMMMMEEE551",
            "555557777777777777777777777777777777777777MMMMMMMMMMMMNNNNNM8551",
            "5555555777777777777777777777777777777777MMMMMMMMMMMMMMMMMMMM5551",
            "5555555555777777777777777777777777777MMMMMMMMMMMMMMMMMMMMMMMM551",
            "1111111111111111111111171111111111111111111111111111111111111111",
        ], palette: [
            PaintColor(id: 1, name: "Morning sky", hex: 0xBBDDD5),
            PaintColor(id: 2, name: "Sky light", hex: 0xD7EAE0),
            PaintColor(id: 3, name: "Cloud", hex: 0xF5F0D9),
            PaintColor(id: 4, name: "Distant sage", hex: 0xA7BE9C),
            PaintColor(id: 5, name: "Meadow", hex: 0x799B75),
            PaintColor(id: 6, name: "Sunlight", hex: 0xFFE4A1),
            PaintColor(id: 7, name: "Deep leaf", hex: 0x345B51),
            PaintColor(id: 8, name: "Leaf", hex: 0x527F62),
            PaintColor(id: 9, name: "Leaf light", hex: 0x9FBD78),
            PaintColor(id: 10, name: "Petal shadow", hex: 0xA94865),
            PaintColor(id: 11, name: "Rose", hex: 0xDB7288),
            PaintColor(id: 12, name: "Petal light", hex: 0xF4ACAF),
            PaintColor(id: 13, name: "Peach shadow", hex: 0xD88C68),
            PaintColor(id: 14, name: "Apricot", hex: 0xF3BD87),
            PaintColor(id: 15, name: "Pollen", hex: 0xB17B3F),
            PaintColor(id: 16, name: "Lavender", hex: 0xA899C5),
            PaintColor(id: 17, name: "Lavender shadow", hex: 0x776B9A),
            PaintColor(id: 18, name: "Clay shadow", hex: 0x9B6555),
            PaintColor(id: 19, name: "Terracotta", hex: 0xCA8C6C),
            PaintColor(id: 20, name: "Clay light", hex: 0xE4AE88),
            PaintColor(id: 21, name: "Soil", hex: 0x674D43),
            PaintColor(id: 22, name: "Garden path", hex: 0xD7C6A0),
            PaintColor(id: 23, name: "Path shade", hex: 0xB7AA8D),
            PaintColor(id: 24, name: "Butterfly", hex: 0xE4B75B),
        ]),
        Puzzle(id: "cabin-64-v1", title: "Cabin at dusk", subtitle: "Warm windows beneath a mountain evening.", symbol: "house", rows: [
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111111111111111114111111111111111111111111111111111111111",
            "1111111111111111111111111111111111111111111114411111111111111111",
            "1111111411111111111111111111111111111111111144411111111111111111",
            "1111111111111111111111111111111111112111111144111111111111111111",
            "1111111111111111111111111111111111222221111144411111111111111111",
            "1111111111111111111111111111111111112111111444411111111111111111",
            "1111111111111111111111111111111111211111111144441111111111111111",
            "2222222222222222222222222222222222222222222244444414422222222222",
            "2222222222222222222222222222222222222222222244444444422222222222",
            "2222222222222262222222222222222222222222222224444444222222222222",
            "2222222222222666222222222222222222222222222222224222222222222222",
            "2222222222226666522222222222222222222222222222222222222222222222",
            "2222222222256666652222222222222222222565222222222222222222222222",
            "2222222222566666665222222222222222LLLLLL522222222222222222422222",
            "2222222222666666665522222222DDD222GGGGG6655222222222222222222222",
            "222222222666665556652222222DDDDD25GGGGG6655522222222222222222222",
            "22222222566665555555522222DDEEEDD5GGGGG6665552222222222222222222",
            "3333333566666555555555333DDEEEEEDDGGGGG6666555533333333333733333",
            "333333566666555555555553DDEEEEEEEDDGGGG5556655553333333337773333",
            "33333555575555555555555DDEEEEEEEEEEDDGG555555555533333333A773333",
            "3333355577755555555555DDDFFFDFFFDFFEDDG555555555555333337A777333",
            "33335555A77555555555DDEEEEEEEEEEEEEEEDD55555555555553333AA777733",
            "37355557A7775555555DDEEEEEEEEEEEEEEEEEDD5555555575555537A7877733",
            "7775555AA777755555DDEFFFDFFFDFFFDFFFDFEED55555577755555A78887777",
            "A775557A777775555DDEEEEEEEEEEEEEEEEEEEEEEDD5555A77555577A988777A",
            "A7775577A7777755DDEEEEEEEEEEEEEEEEEEEEEEEEDD557A7775555A8988877A",
            "A777837AA777733DDDFFDFFFDFFFDFFFDFFFDFFFDDDDD57A777755AA9988887A",
            "A77888AA777777DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDAA77733AA8998888AA",
            "777988A7A7777IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII77777777999888887",
            "A789888AA7777777GGGGGGGGGGGGGGGGGGGGGGGGGGGG777A777771899888888A",
            "A799888AA7777711GGHDDDDDDHHGGGGGGGHHDDDDDDGG1AAA77771A9989888888",
            "A8998888A777777AGGHDKGJJDHHGJJJJJGHHDKGJJDGGAAAA7777A89899888888",
            "7999888887777777GGIDKGJJDIIGJKKKJGIIDKGJJDGG7777777AA98999888888",
            "8998888887777777GGGDGGGGDGGGJKKKJGGGDGGGGDGG111GG177889999888888",
            "9989888888BBBBBBGGHDJGJJDHHGJKKKJGHHDJGJJDGGBBBBBBBBB99999888888",
            "9899888888BBBBBBGGHDJGJJDHHGJKKKJGHHDJGJJDGGBBBBBBBB999998888888",
            "89998888888BBBCCGGIDDDDDDIIGJJJJJGIIDDDDDDGGBBBBBBB9999989888888",
            "9999888888CCCCCCGGIIIIIIIIGGJJJJJGGIIIIIIIIGBBBBBB99999899888888",
            "99988888888CCCCCGGHHHHHHHHHGJJJGJGHHHHHHHHGGBBBBB999998999888888",
            "998988888888CCCCGGHHHHHHHHHGJJJJJGHHHHHHHHGGBBBB8888899999888898",
            "9899888888888CCCGGIIIIIIIIIGJJJJJGIIIIIIIHGGCNNNNNNN999999888898",
            "89998888888888CCGGGGGGGGGGGGGGGGGGGGGGGGGGGGNNNNNN89999999888998",
            "999988888888888LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLNNNN899999999889998",
            "99998888888CCCCLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLNOO9999999999889998",
            "9999888888888CCCCCCBCCCCCCCCMMMMMMCCCCCNNNNNNNN99999999999899998",
            "99998888888888CCCCCCCCCCC4ACMMMMMMCACCCNNNNNNN999999999999889998",
            "999988888888888CBCCCCCCCCCCMMMMMMMMCCCNNNNNNN8888888888888899998",
            "9999888888888888CCCCCCCCCCCMMMMMMMMCCCNNNNNNCCCCCACC4CCCCG999988",
            "88888888888888888CCCCCCCCCMMMMMMMMMCCNNNNNNNNACCCCCCCCCCC9999898",
            "CCCGGCCCCCCCCCCCC4CCCCCCCCMMMMMMMMMMCNNOOOOOOCCCCC4CBCCC99998998",
            "CCCGGCCC4CCCCCCCCCCCCCCCCMLLLLLLLLMMNNNNNNNNNNCCCCCCCCC888899998",
            "CCCBCCCCCCCCCCCCCCCCCBCCCMMMMMMMMMMMNNNNNNNNNNCCCC4CCCCCC8999998",
            "CCCCCCCCCCCCC4CACCCCCCCCMMMMMMMMMMMMMNNNNNNNNNCCCCCCCCCC89999998",
            "CCCCCCCCCCCC4CCCCCBCCCCCMMMMMMMMMMMMMNNNNNNNNNNNNNNNNNN999999998",
            "CCCCCCCCCCCCCCCCCBCCCCCMMMMMMMMMMMMMMANNNNNNNNNNNNNNNN9999999998",
            "CCCCCCCCCCCCCCCCCCCCCCCMMMMMMMMMMMMMMMNNNNNNNOOOOOOOO88888888888",
            "CCCBC4CCCACCCACCCCCC4CMMLLLLLLLLLLLLMMCNNNNNNNNNNNNNNNNNNNNNNNGG",
            "CCCCCCCCCCCCCCCCCCCCCCMMMMMMMMMMMMMMMMCCNNNNNNNNNNNNOOOOOONNNNGG",
            "BBBBBBBBBBBBBBBBBBBBBBBABABBBBBBBABBBBBBBBBBBBBBBBBBBB4BBBBB4BGG",
        ], palette: [
            PaintColor(id: 1, name: "Evening sky", hex: 0x7788AE),
            PaintColor(id: 2, name: "Sky glow", hex: 0xAFACC2),
            PaintColor(id: 3, name: "Peach dusk", hex: 0xE9BCA9),
            PaintColor(id: 4, name: "Moonlight", hex: 0xFFF0C3),
            PaintColor(id: 5, name: "Far mountains", hex: 0x6C789A),
            PaintColor(id: 6, name: "Mountain light", hex: 0x98A2B9),
            PaintColor(id: 7, name: "Distant pines", hex: 0x496B79),
            PaintColor(id: 8, name: "Pine shadow", hex: 0x254B52),
            PaintColor(id: 9, name: "Pine", hex: 0x3D6C61),
            PaintColor(id: 10, name: "Pine light", hex: 0x729177),
            PaintColor(id: 11, name: "Meadow shadow", hex: 0x3E6257),
            PaintColor(id: 12, name: "Meadow", hex: 0x68876A),
            PaintColor(id: 13, name: "Roof shadow", hex: 0x514654),
            PaintColor(id: 14, name: "Slate", hex: 0x796477),
            PaintColor(id: 15, name: "Slate light", hex: 0xA6858A),
            PaintColor(id: 16, name: "Timber shadow", hex: 0x77554C),
            PaintColor(id: 17, name: "Cedar", hex: 0xA77B5D),
            PaintColor(id: 18, name: "Wood light", hex: 0xD1A276),
            PaintColor(id: 19, name: "Window gold", hex: 0xF5C76C),
            PaintColor(id: 20, name: "Window light", hex: 0xFFE6A1),
            PaintColor(id: 21, name: "Stone", hex: 0xA6A69B),
            PaintColor(id: 22, name: "Path", hex: 0xC6B69A),
            PaintColor(id: 23, name: "Water", hex: 0x647F98),
            PaintColor(id: 24, name: "Reflection", hex: 0xA6BBC1),
        ]),
        Puzzle(id: "wings-64-v1", title: "Wildflower wings", subtitle: "Discover every pattern in a meadow butterfly.", symbol: "sparkles", rows: [
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111111111111111111111111111111111111111111111111111111111",
            "1111111111113111111111111111111111111111111111111111111111111111",
            "1111111133333333311111111111111111111111111111111111111111111111",
            "1111111333333333331111111111111111111111111111111111111111111111",
            "1111113333333333333111111111111111111111111111111111111111111111",
            "1111133333333333333311111111111111111111111111111111111111111111",
            "1111133333333333333311111111111111111111111111111111111111111111",
            "1111133333333333333311111111111111111111111111111111111111111111",
            "1111333333333333333331111111111111111111111111111111111111111111",
            "1111133999999933333311111111111111111111111111111199999911111111",
            "1111133999999999333311111111111111111111111111119999999991111111",
            "2222233999999999993322222222222222222222222222999999999992222222",
            "22222239EAAAAA999992222222222222222222222222299999AAAAAE92222222",
            "22222299EAAAAAAA99999222222222222222222222299999AAAAAAAE99222222",
            "22222299EA9AAAAAA99999922222222222222222299999AAAAAAA9AE99222222",
            "22222299AAB9BBAAAAA99999222222222222222999999AAAAABB9AA999222222",
            "22222999EAAB9BBBAAAAA999922E22222222E229999AAAAABBB9BAAE99222222",
            "22222299EAABB9CBBBAAAA9999229222222922999AAAAABBBC9BBAAE99222222",
            "22222299EAABBB9CCBBBAAA999229222222922999AAABBBCC9BBBAAE99222222",
            "22222299AAABBBC9CACBBAAA9992292222922999AABBBCAC9CBBAAA999222222",
            "22222299AAAABBCCAAACBBAAA99929222292999AAABCCAAACCBBAAA999222222",
            "222222999A9ABBCAADAACBBAA99922999922999AABBCAADAACBBA9A992222222",
            "2222222999A99BCADDDACCBBAA999299992999AABBCDADDDABB99A9992222222",
            "2222222999AAB9BAADAADCCBAAA9999999999AABBCDDAADAAB9AAA9992222222",
            "2222222999EAAA99AAAC9DCCBAA9992992999AABCDD9CAAA99AAAE9992222222",
            "2222222999E9AAAB9ABCC9DCCBAA999I9999AABCDC9CCBA9BAAA9E9992222222",
            "2222222999E9AAAAB99BCC9CCBBAA99I999AABCCC9CBB99BAAAA9E9922222222",
            "2222222299999AAAABB9BBC9CCBAA99I99AABBCC9CBB9BBAAAA9999444222222",
            "2222222229999AA99ABB99BB9CBAA99I99AABCC9BB99BAA99A99994444444222",
            "111111114499999EA99AAB99B9CAA99I99AABC9B99BAA99AE999944444444441",
            "111111444449999E99A999AB9B9AA99I99AAB9B9BA999A99E999444444444441",
            "111144444444999E9999AA99A999A99I99AA999A99AA9999E994444444444441",
            "114444444444499999999EAA9999999I99A99999AAE999999944444444444441",
            "444444444444449999999E99AAA9999I99999AA999E999999444444444444441",
            "444444444444449999999E999999999I9999999999E999999944444444444441",
            "4444444444449999999999999999999I99999999999999999999444444444551",
            "4444444449999999FFFFFF999FFF999I99F9FFF999FFFFF99999994444555551",
            "44444444499999FFFFG999GGGGGF9F9I99F9GGGGGG999FFFF999994455555551",
            "44444444499EFFF9999GGGGGGGG9FF9I99FF9GGGGGGGG9999FF9E95555555551",
            "44444444499E999GGGGHFHHHHG9FFF9I99FFG9GHHHHFGGGGF999E95555555551",
            "44444444499E9FFFGGGFFFHHG9GFF99I999FGG9HHHFFFGGGFFF9E95555555551",
            "4444445559999FFFFGFFEFFHG9GFF999999FGG9GHFFEFFGFFF99995555555551",
            "44455555599999FFFGGFFFGG9GFF99999999FFG9GGFFFGGFFF999955KKKKL551",
            "55555555559999FFFFGGFGG9GFF999599599FFFG9GGFGGFFFF999955KKKKL551",
            "55555555555999FEFFGGGG9GFFE9995995999EFFG9GGGFFFE999955KL6JLLL51",
            "555KKKKL5555999EFFFFFF9FF9E9955555999E9FF9FFFFFFE999555KKJJJKL51",
            "555KKKKL5555999E99FFF9FF99E9555555559E99FF9FFF99E999555LLLJKLL51",
            "55KL6JLLL555599999999FF999955555555559999FF9999999955555KKLKL551",
            "55KKJJJKL555559999999E99955555555555559999E9999999555555LLLLL551",
            "55LLLJKLL555559999999E99555555555555555599E999999555555555655551",
            "555KKLKL5555555555999E95555555555555555559ELL9LL5555555555655551",
            "555LLLLL555LL5LL55555555555555555555555555KKKKKKL555557555655551",
            "5555565555KKKKKKL5555555555555555555555555KKKKKKL555557775658551",
            "5555565555KKKKKKL555555855555555555555555KKKKKKKLL55555777658551",
            "578556555KKKKKKKLL5555585555555555555555KKLL6JJLLKL5555777658551",
            "57875655KKLL6JJLLKL5555855555KKKKL555555LKKLJJJKKLL5855777658551",
            "55877655LKKLJJJKKLL5555855555KKKKL555555LLLLJJJKLLL5855555658551",
            "55877655LLLLJJJKLLL555558555KL6JLLL555555LLLKLKKLL55855555655851",
            "557876555LLLKLKKLL5555558555KKJJJKL5555555KKKLKKL555855555655851",
            "5558565555KKKLKKL55555558555LLLJKLL5555555LLLLLLL555585555655851",
            "5558565555LLLLLLL555555585555KKLKL555555555LL6LL5555585555655851",
            "11181611111LL6LL1111111181111LLLLL111111171116111111181111611811",
        ], palette: [
            PaintColor(id: 1, name: "Pale sky", hex: 0xCDDCD6),
            PaintColor(id: 2, name: "Sky light", hex: 0xE3E8D8),
            PaintColor(id: 3, name: "Sun haze", hex: 0xF8EDD1),
            PaintColor(id: 4, name: "Distant meadow", hex: 0xA9B69A),
            PaintColor(id: 5, name: "Grass", hex: 0x779978),
            PaintColor(id: 6, name: "Leaf shadow", hex: 0x3E6558),
            PaintColor(id: 7, name: "Leaf", hex: 0x5D8765),
            PaintColor(id: 8, name: "Leaf light", hex: 0xA1B97B),
            PaintColor(id: 9, name: "Wing outline", hex: 0x3D3D59),
            PaintColor(id: 10, name: "Indigo", hex: 0x5D5282),
            PaintColor(id: 11, name: "Violet", hex: 0x8774AD),
            PaintColor(id: 12, name: "Lavender", hex: 0xB59FD0),
            PaintColor(id: 13, name: "Lilac", hex: 0xDECEE6),
            PaintColor(id: 14, name: "Wing pearl", hex: 0xFFF1D3),
            PaintColor(id: 15, name: "Rose shadow", hex: 0xA2537C),
            PaintColor(id: 16, name: "Rose", hex: 0xCE7CA0),
            PaintColor(id: 17, name: "Blush", hex: 0xEAAEBF),
            PaintColor(id: 18, name: "Body light", hex: 0x8B7690),
            PaintColor(id: 19, name: "Pollen", hex: 0xD5A456),
            PaintColor(id: 20, name: "Daisy", hex: 0xF5E4B6),
            PaintColor(id: 21, name: "Wildflower", hex: 0xD99572),
        ]),
    ]
}
// END GENERATED SCENES
