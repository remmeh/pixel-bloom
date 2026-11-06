import SwiftUI

private let paper = Color(red: 0.97, green: 0.96, blue: 0.93)
private let secondaryInk = Color(red: 0.35, green: 0.36, blue: 0.32)

struct ContentView: View {
    @EnvironmentObject private var store: PaintStore
    @State private var selectedID: String? = Puzzle.all.first?.id
    var body: some View {
        NavigationSplitView {
            List(Puzzle.all, selection: $selectedID) { puzzle in
                PuzzleRow(puzzle: puzzle, progress: store.progress(in: puzzle))
                    .equatable()
                    .tag(puzzle.id)
                    .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(paper)
            .navigationTitle("Pixel Bloom")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("A moment of color", systemImage: "leaf")
                        .font(.subheadline.weight(.semibold))
                    Text("Pick a picture. Find your rhythm.")
                        .font(.caption).foregroundStyle(secondaryInk)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
            }
        } detail: {
            if let puzzle = Puzzle.all.first(where: { $0.id == selectedID }) {
                ColoringView(puzzle: puzzle).id(puzzle.id)
            } else {
                ContentUnavailableView("Choose a picture", systemImage: "square.grid.3x3", description: Text("Your next little masterpiece is waiting."))
            }
        }
        // The canvas uses fixed light paper colors, so its text and controls need a matching appearance.
        .preferredColorScheme(.light)
    }
}

private struct PuzzleRow: View, Equatable {
    let puzzle: Puzzle
    let progress: Double

    var body: some View {
        HStack(spacing: 14) {
            ArtworkPreview(puzzle: puzzle)
                .equatable()
                .frame(width: 62, height: 62)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                Text(puzzle.title).font(.headline)
                Text(progress == 1 ? "Completed" : "\(Int(progress * 100))% colored")
                    .font(.caption).foregroundStyle(secondaryInk)
                ProgressView(value: progress).accessibilityLabel("Coloring progress")
            }
        }
        .padding(.vertical, 8)
    }
}

struct ArtworkPreview: View, Equatable {
    let puzzle: Puzzle
    var body: some View {
        Canvas { context, size in
            let unit = min(size.width / CGFloat(puzzle.width), size.height / CGFloat(puzzle.height))
            for (index, number) in puzzle.cells.enumerated() where number > 0 {
                if let color = puzzle.colorsByNumber[number] {
                    let rect = CGRect(x: CGFloat(index % puzzle.width) * unit,
                                      y: CGFloat(index / puzzle.width) * unit, width: unit, height: unit)
                    context.fill(Path(rect), with: .color(color.color))
                }
            }
        }.padding(6).accessibilityLabel("\(puzzle.title), pixel art preview")
    }
}

struct ColoringView: View {
    let puzzle: Puzzle
    @EnvironmentObject private var store: PaintStore
    @State private var selectedColor = 1
    @State private var zoom: CGFloat = 1
    @GestureState private var pinchScale: CGFloat = 1
    private var effectiveZoom: CGFloat { min(3, max(1, zoom * pinchScale)) }
    @State private var hint: Int?
    @State private var showReset = false
    @State private var message = "Choose a color, then tap its matching numbers."
    private var isComplete: Bool { store.progress(in: puzzle) == 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(puzzle.title).font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text(puzzle.subtitle).font(.subheadline).foregroundStyle(secondaryInk)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(store.progress(in: puzzle), format: .percent.precision(.fractionLength(0)))
                        .font(.system(.title2, design: .rounded, weight: .semibold)).monospacedDigit()
                    Text("\(store.filled(in: puzzle).count) / \(puzzle.paintable.count) pixels")
                        .font(.caption).foregroundStyle(secondaryInk)
                }
            }.padding(24)

            HStack {
                Label(isComplete ? "Beautifully done!" : "One pixel at a time", systemImage: isComplete ? "checkmark.seal.fill" : "square.grid.3x3")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button { zoom = max(1, zoom - 0.5) } label: { Image(systemName: "minus.magnifyingglass") }
                    .disabled(zoom <= 1).accessibilityLabel("Zoom out")
                Text("\(Int(effectiveZoom * 100))% ").font(.caption.monospacedDigit()).frame(width: 48)
                Button { zoom = min(3, zoom + 0.5) } label: { Image(systemName: "plus.magnifyingglass") }
                    .disabled(zoom >= 3).accessibilityLabel("Zoom in")
            }.buttonStyle(.bordered).padding(.horizontal, 24).padding(.bottom, 12)

            PixelBoard(puzzle: puzzle, filled: store.filled(in: puzzle), selectedColor: selectedColor, zoom: effectiveZoom, hint: $hint) { index in
                if store.paint(index, color: selectedColor, in: puzzle) {
                    hint = nil
                    message = isComplete ? "Your picture is complete. Beautifully done!" : "Nice! Keep finding \(selectedColor)s."
                } else if !store.filled(in: puzzle).contains(index) {
                    message = "Select color \(puzzle.cells[index]) to fill that square."
                }
            }
            .simultaneousGesture(
                MagnifyGesture()
                    .updating($pinchScale) { value, scale, _ in scale = value.magnification }
                    .onEnded { value in zoom = min(3, max(1, zoom * value.magnification)) }
            )
            .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(isComplete ? "Picture complete — take a moment to enjoy it." : message)
                        .font(.footnote).foregroundStyle(secondaryInk).accessibilityAddTraits(.updatesFrequently)
                    Spacer()
                    Button { findHint() } label: { Label("Hint", systemImage: "lightbulb") }
                        .disabled(isComplete)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(puzzle.palette) { paint in
                            paletteButton(paint)
                        }
                    }.padding(4)
                }
                Text("Match the numbers • Pinch to zoom • Scroll to explore")
                    .font(.caption2).foregroundStyle(secondaryInk)
            }.padding(24)
        }
        .background(paper)
        .navigationTitle("Color by number")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Start over", systemImage: "arrow.counterclockwise") { showReset = true }
                    .disabled(store.filled(in: puzzle).isEmpty)
            }
        }
        .confirmationDialog("Start this picture over?", isPresented: $showReset, titleVisibility: .visible) {
            Button("Erase this picture’s progress", role: .destructive) {
                store.reset(puzzle)
                hint = nil
                selectedColor = 1
                message = "A fresh canvas. Choose a color to begin."
            }
        } message: { Text("Your other pictures will keep their progress.") }
        .sensoryFeedback(.selection, trigger: store.filled(in: puzzle).count)
    }

    private func paletteButton(_ paint: PaintColor) -> some View {
        let remaining = store.remaining(paint.id, in: puzzle)
        return Button {
            selectedColor = paint.id
            hint = nil
            message = remaining == 0 ? "All \(paint.name.lowercased()) squares are done!" : "Find \(remaining) squares marked \(paint.id)."
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15).fill(paint.color)
                    // Use dark ink on a white badge so every palette number stays legible.
                    Text(remaining == 0 ? "✓" : "\(paint.id)")
                        .font(.headline).foregroundStyle(.black)
                        .frame(width: 28, height: 28).background(.white.opacity(0.92), in: Circle())
                }.frame(width: 58, height: 54)
                Text(paint.name).font(.caption2).foregroundStyle(.primary).lineLimit(1)
                Text("\(remaining) left").font(.caption2).foregroundStyle(secondaryInk)
            }
            .padding(6)
            .background(selectedColor == paint.id ? Color.primary.opacity(0.07) : Color.clear, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(selectedColor == paint.id ? Color.primary.opacity(0.65) : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color \(paint.id), \(paint.name), \(remaining) squares remaining")
        .accessibilityAddTraits(selectedColor == paint.id ? .isSelected : [])
    }

    private func findHint() {
        var candidates = puzzle.cells.indices.filter { puzzle.cells[$0] == selectedColor && !store.filled(in: puzzle).contains($0) }
        if candidates.isEmpty, let next = puzzle.cells.indices.first(where: { puzzle.cells[$0] > 0 && !store.filled(in: puzzle).contains($0) }) {
            selectedColor = puzzle.cells[next]
            candidates = [next]
        }
        // Clearing first allows a repeated hint to scroll back to the same square.
        hint = nil
        let next = candidates.first
        Task { @MainActor in
            await Task.yield()
            hint = next
            message = "The outlined square is a \(selectedColor). Tap it to fill."
        }
    }
}

struct PixelBoard: View {
    let puzzle: Puzzle
    let filled: Set<Int>
    let selectedColor: Int
    let zoom: CGFloat
    @Binding var hint: Int?
    let onPaint: (Int) -> Void

    var body: some View {
        GeometryReader { geometry in
            let unit = max(20, min((geometry.size.width - 48) / CGFloat(puzzle.width),
                                   (geometry.size.height - 48) / CGFloat(puzzle.height))) * zoom
            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(unit), spacing: 0), count: puzzle.width), spacing: 0) {
                        ForEach(puzzle.cells.indices, id: \.self) { index in
                            PixelCell(index: index, width: puzzle.width, number: puzzle.cells[index],
                                      paint: puzzle.colorsByNumber[puzzle.cells[index]],
                                      filled: filled.contains(index), selectedColor: selectedColor,
                                      isHint: hint == index, unit: unit, onPaint: onPaint)
                                .equatable()
                                .id(index)
                        }
                    }
                    .frame(width: CGFloat(puzzle.width) * unit)
                    .padding(24)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                }
                .onChange(of: hint) { _, index in
                    if let index { withAnimation { proxy.scrollTo(index, anchor: .center) } }
                }
            }
        }
    }
}

private struct PixelCell: View, Equatable {
    let index: Int
    let width: Int
    let number: Int
    let paint: PaintColor?
    let filled: Bool
    let selectedColor: Int
    let isHint: Bool
    let unit: CGFloat
    let onPaint: (Int) -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.index == rhs.index && lhs.width == rhs.width && lhs.number == rhs.number &&
        lhs.paint == rhs.paint && lhs.filled == rhs.filled && lhs.selectedColor == rhs.selectedColor &&
        lhs.isHint == rhs.isHint && lhs.unit == rhs.unit
    }

    @ViewBuilder var body: some View {
        if number == 0 {
            Color.clear.frame(width: unit, height: unit).accessibilityHidden(true)
        } else {
            Button { onPaint(index) } label: {
                ZStack {
                    Rectangle().fill(filled ? (paint?.color ?? .gray) : (selectedColor == number ? (paint?.color.opacity(0.18) ?? .white) : .white))
                    if !filled {
                        Text("\(number)").font(.system(size: min(22, unit * 0.42), weight: selectedColor == number ? .bold : .regular, design: .rounded))
                            .foregroundStyle(selectedColor == number ? Color.primary : secondaryInk)
                    }
                    Rectangle().strokeBorder(isHint ? Color.primary : Color.black.opacity(0.09), lineWidth: isHint ? 3 : 0.5)
                }.frame(width: unit, height: unit).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Row \(index / width + 1), column \(index % width + 1), color \(number), \(filled ? "filled" : "unfilled")\(isHint ? ", hint" : "")")
            .accessibilityHint(filled ? "Already colored" : "Select color \(number), then activate to fill")
        }
    }
}
