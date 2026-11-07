import SwiftUI
import UIKit

private let paper = Color(red: 0.97, green: 0.96, blue: 0.93)
private let secondaryInk = Color(red: 0.35, green: 0.36, blue: 0.32)

struct ContentView: View {
    @EnvironmentObject private var store: PaintStore
    @State private var selectedID: String? = Puzzle.all.first?.id
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedID) {
                Section("Detailed scenes") {
                    ForEach(Puzzle.detailed) { puzzle in
                        puzzleRow(puzzle)
                    }
                }
                Section("Little pictures") {
                    ForEach(Puzzle.quick) { puzzle in
                        puzzleRow(puzzle)
                    }
                }
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

    private func puzzleRow(_ puzzle: Puzzle) -> some View {
        PuzzleRow(puzzle: puzzle, progress: store.progress(in: puzzle))
            .equatable()
            .tag(puzzle.id)
            .listRowBackground(Color.clear)
    }
}

private struct PuzzleRow: View, Equatable {
    let puzzle: Puzzle
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(puzzle.title).font(.headline)
            Text("\(puzzle.width) × \(puzzle.height) · \(puzzle.palette.count) colors")
                .font(.caption2).foregroundStyle(secondaryInk)
            Text(progress == 1 ? "Completed" : "\(Int(progress * 100))% colored")
                .font(.caption).foregroundStyle(secondaryInk)
            ProgressView(value: progress).accessibilityLabel("Coloring progress")
        }
        .padding(.vertical, 8)
    }
}

struct ColoringView: View {
    let puzzle: Puzzle
    @EnvironmentObject private var store: PaintStore
    @State private var selectedColor = 1
    @State private var zoom: CGFloat
    @GestureState private var pinchScale: CGFloat = 1
    private var maximumZoom: CGFloat { puzzle.width > 16 ? 10 : 3 }
    private var effectiveZoom: CGFloat { min(maximumZoom, max(1, zoom * pinchScale)) }

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        _zoom = State(initialValue: puzzle.width > 16 ? 3 : 1)
    }
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
                Label("Drag to color", systemImage: "hand.draw")
                    .font(.subheadline)
                Spacer()
                Button { zoom = max(1, zoom - 0.5) } label: { Image(systemName: "minus.magnifyingglass") }
                    .disabled(zoom <= 1).accessibilityLabel("Zoom out")
                Text("\(Int(effectiveZoom * 100))% ").font(.caption.monospacedDigit()).frame(width: 48)
                if puzzle.width > 16 {
                    Button("Overview") { zoom = 1 }
                        .accessibilityHint("Zoom out to see the whole canvas and your coloring progress")
                }
                Button { zoom = min(maximumZoom, zoom + 0.5) } label: { Image(systemName: "plus.magnifyingglass") }
                    .disabled(zoom >= maximumZoom).accessibilityLabel("Zoom in")
            }.buttonStyle(.bordered).padding(.horizontal, 24).padding(.bottom, 12)

            PixelBoard(puzzle: puzzle, filled: store.filled(in: puzzle), selectedColor: selectedColor,
                       zoom: effectiveZoom, isPinching: pinchScale != 1, hint: $hint) { indices in
                if store.paint(indices, color: selectedColor, in: puzzle) > 0 {
                    hint = nil
                    message = isComplete ? "Your picture is complete. Beautifully done!" : "Nice! Keep finding \(selectedColor)s."
                } else if indices.count == 1, let index = indices.first, !store.filled(in: puzzle).contains(index) {
                    message = "Select color \(puzzle.cells[index]) to fill that square."
                }
            }
            .simultaneousGesture(
                MagnifyGesture()
                    .updating($pinchScale) { value, scale, _ in scale = value.magnification }
                    .onEnded { value in zoom = min(maximumZoom, max(1, zoom * value.magnification)) }
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
                Text("One finger to color • Three fingers to move • Pinch to zoom")
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
    let isPinching: Bool
    @Binding var hint: Int?
    let onPaint: ([Int]) -> Void

    var body: some View {
        GeometryReader { geometry in
            let minimumUnit: CGFloat = puzzle.width > 16 ? 4 : 20
            let unit = max(minimumUnit, min((geometry.size.width - 48) / CGFloat(puzzle.width),
                                           (geometry.size.height - 48) / CGFloat(puzzle.height))) * zoom
            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    LazyVGrid(columns: (0..<puzzle.tileColumns).map { column in
                        GridItem(.fixed(CGFloat(min(Puzzle.tileSize, puzzle.width - column * Puzzle.tileSize)) * unit), spacing: 0)
                    }, spacing: 0) {
                        ForEach(puzzle.tiles) { tile in
                            PixelTile(puzzle: puzzle, tile: tile, filled: filled.intersection(tile.indices),
                                      selectedColor: selectedColor, unit: unit,
                                      hint: hint.flatMap { tile.indices.contains($0) ? $0 : nil },
                                      onPaint: { onPaint([$0]) })
                                .equatable()
                                .id(tile.id)
                        }
                    }
                    .frame(width: CGFloat(puzzle.width) * unit)
                    .background {
                        CanvasTouchInput(isPinching: isPinching) { start, end in
                            onPaint(puzzle.strokeIndices(from: start, to: end, unit: unit))
                        }
                        .allowsHitTesting(false)
                    }
                    .padding(24)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                }
                .defaultScrollAnchor(.center)
                .onChange(of: hint) { _, index in
                    if let index {
                        withAnimation { proxy.scrollTo(puzzle.tileID(containing: index), anchor: .center) }
                    }
                }
            }
        }
    }
}

// Each tile is one drawing surface, rather than 64 separately laid-out buttons.
// Only the changed tile redraws after painting; offscreen tile rows stay lazy.
private struct PixelTile: View, Equatable {
    let puzzle: Puzzle
    let tile: Puzzle.Tile
    let filled: Set<Int>
    let selectedColor: Int
    let unit: CGFloat
    let hint: Int?
    let onPaint: (Int) -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.puzzle.id == rhs.puzzle.id && lhs.tile.id == rhs.tile.id &&
        lhs.filled == rhs.filled && lhs.selectedColor == rhs.selectedColor &&
        lhs.unit == rhs.unit && lhs.hint == rhs.hint
    }

    var body: some View {
        Canvas { context, _ in
            var labels: [Int: GraphicsContext.ResolvedText] = [:]
            if unit >= 11 {
                for paint in puzzle.palette {
                    let size = min(22, unit * (paint.id >= 10 ? 0.34 : 0.42))
                    labels[paint.id] = context.resolve(Text("\(paint.id)")
                        .font(.system(size: size, weight: selectedColor == paint.id ? .bold : .regular, design: .rounded))
                        .foregroundStyle(selectedColor == paint.id ? Color.primary : secondaryInk))
                }
            }
            var grid = Path()
            for index in tile.indices {
                let number = puzzle.cells[index]
                guard number > 0 else { continue }
                let rect = CGRect(x: CGFloat(index % puzzle.width - tile.column) * unit,
                                  y: CGFloat(index / puzzle.width - tile.row) * unit,
                                  width: unit, height: unit)
                let paint = puzzle.colorsByNumber[number]?.color ?? .gray
                let isFilled = filled.contains(index)
                context.fill(Path(rect), with: .color(isFilled ? paint : (selectedColor == number ? paint.opacity(0.18) : .white)))
                if !isFilled, let label = labels[number] {
                    context.draw(label, at: CGPoint(x: rect.midX, y: rect.midY))
                }
                if unit >= 10 { grid.addRect(rect) }
            }
            context.stroke(grid, with: .color(.black.opacity(0.09)), lineWidth: 0.5)
            if let hint {
                let rect = CGRect(x: CGFloat(hint % puzzle.width - tile.column) * unit + 1.5,
                                  y: CGFloat(hint / puzzle.width - tile.row) * unit + 1.5,
                                  width: unit - 3, height: unit - 3)
                context.stroke(Path(rect), with: .color(.primary), lineWidth: 3)
            }
        }
        .frame(width: CGFloat(tile.width) * unit, height: CGFloat(tile.height) * unit)
        .accessibilityChildren {
            ForEach(tile.indices.filter { puzzle.cells[$0] > 0 }, id: \.self) { index in
                Button { onPaint(index) } label: {
                    Text("Row \(index / puzzle.width + 1), column \(index % puzzle.width + 1), color \(puzzle.cells[index]), \(filled.contains(index) ? "filled" : "unfilled")\(hint == index ? ", hint" : "")")
                }
                .accessibilityHint(filled.contains(index) ? "Already colored" : "Select color \(puzzle.cells[index]), then activate to fill")
            }
        }
    }
}


// UIKit exposes touch-count limits, allowing the existing SwiftUI scroll view
// to pan with three fingers while a separate recognizer paints with one.
struct CanvasTouchInput: UIViewRepresentable {
    let isPinching: Bool
    let onStroke: (CGPoint, CGPoint) -> Void

    func makeUIView(context: Context) -> CanvasTouchView {
        CanvasTouchView()
    }

    func updateUIView(_ view: CanvasTouchView, context: Context) {
        view.onStroke = onStroke
        view.isPinching = isPinching
        view.connectToScrollView()
    }

    static func dismantleUIView(_ view: CanvasTouchView, coordinator: ()) {
        view.disconnectFromScrollView()
    }
}

final class CanvasTouchView: UIView, UIGestureRecognizerDelegate {
    var onStroke: (CGPoint, CGPoint) -> Void = { _, _ in }
    var isPinching = false {
        didSet { if isPinching { lastPoint = nil } }
    }
    private(set) weak var connectedScrollView: UIScrollView?
    private var previousMinimumTouches = 1
    private var lastPoint: CGPoint?
    private(set) lazy var paintPan: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(paintDragged(_:)))
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 1
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()
    private(set) lazy var paintTap: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(paintTapped(_:)))
        gesture.numberOfTouchesRequired = 1
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        gesture.require(toFail: paintPan)
        return gesture
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        connectToScrollView()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            disconnectFromScrollView()
        } else {
            connectToScrollView()
            // SwiftUI may finish inserting the background after this callback.
            DispatchQueue.main.async { [weak self] in self?.connectToScrollView() }
        }
    }

    func connectToScrollView() {
        var ancestor = superview
        while let view = ancestor, !(view is UIScrollView) { ancestor = view.superview }
        guard let scrollView = ancestor as? UIScrollView else {
            disconnectFromScrollView()
            return
        }
        guard connectedScrollView !== scrollView else { return }
        disconnectFromScrollView()
        connectedScrollView = scrollView
        previousMinimumTouches = scrollView.panGestureRecognizer.minimumNumberOfTouches
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 3
        scrollView.addGestureRecognizer(paintPan)
        scrollView.addGestureRecognizer(paintTap)
    }

    func disconnectFromScrollView() {
        guard let scrollView = connectedScrollView else { return }
        scrollView.panGestureRecognizer.minimumNumberOfTouches = previousMinimumTouches
        scrollView.removeGestureRecognizer(paintPan)
        scrollView.removeGestureRecognizer(paintTap)
        connectedScrollView = nil
        lastPoint = nil
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // The recognizers live on the scroll view, but only paint inside the grid.
        bounds.contains(touch.location(in: self)) && !isPinching && !UIAccessibility.isVoiceOverRunning
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        // Let three-finger scrolling and the parent's pinch gesture take over.
        gestureRecognizer === paintPan || other === paintPan
    }

    @objc private func paintTapped(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, !isPinching else { return }
        let point = gesture.location(in: self)
        onStroke(point, point)
    }

    @objc private func paintDragged(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)
        let translation = gesture.translation(in: self)
        handlePaintPan(state: gesture.state, touches: gesture.numberOfTouches, point: point,
                       start: CGPoint(x: point.x - translation.x, y: point.y - translation.y))
    }

    // Shared with tests to verify that a second touch or cancellation ends the
    // stroke, without joining it to the next one-finger stroke.
    func handlePaintPan(state: UIGestureRecognizer.State, touches: Int, point: CGPoint, start: CGPoint) {
        guard !isPinching, touches <= 1 else { lastPoint = nil; return }
        switch state {
        case .began:
            guard touches == 1 else { return }
            lastPoint = point
            onStroke(start, point)
        case .changed:
            guard touches == 1, let previous = lastPoint else { return }
            lastPoint = point
            onStroke(previous, point)
        case .ended:
            if let previous = lastPoint { onStroke(previous, point) }
            lastPoint = nil
        case .cancelled, .failed:
            lastPoint = nil
        default:
            break
        }
    }
}
