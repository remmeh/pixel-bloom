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
        let parsed = rows.flatMap { $0.map { $0.wholeNumberValue ?? 0 } }
        cells = parsed
        paintable = Set(parsed.indices.filter { parsed[$0] > 0 })
        cellsByColor = Dictionary(grouping: parsed.indices.filter { parsed[$0] > 0 }, by: { parsed[$0] })
            .mapValues { Set($0) }
        colorsByNumber = Dictionary(uniqueKeysWithValues: palette.map { ($0.id, $0) })
    }

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
