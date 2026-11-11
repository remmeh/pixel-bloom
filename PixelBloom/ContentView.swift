import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass

private let paper = Color(red: 0.97, green: 0.96, blue: 0.93)
private let secondaryInk = Color(red: 0.35, green: 0.36, blue: 0.32)

struct ContentView: View {
    @EnvironmentObject private var store: PaintStore
    @State private var selectedID: String? = Puzzle.all.first?.id
    @State private var isCreatingScene = false
    @State private var sceneToDelete: Puzzle?
    @State private var showsDeleteError = false
    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                List(selection: $selectedID) {
                    Section("My scenes") {
                        Button {
                            isCreatingScene = true
                        } label: {
                            Label("Create a scene", systemImage: "sparkles")
                        }
                        ForEach(store.generatedPuzzles) { puzzle in
                            puzzleRow(puzzle)
                                .swipeActions(allowsFullSwipe: false) {
                                    Button { sceneToDelete = puzzle } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                                .contextMenu {
                                    Button(role: .destructive) { sceneToDelete = puzzle } label: {
                                        Label("Delete scene", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    Section("Detailed scenes") {
                        ForEach(Puzzle.detailed) { puzzle in
                            puzzleRow(puzzle)
                        }
                    }
                    Section("Pusheen") {
                        puzzleRow(Puzzle.pusheen)
                    }
                    Section("Sanrio characters") {
                        ForEach(Puzzle.sanrio) { puzzle in
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
                if let puzzle = store.generatedPuzzles.first(where: { $0.id == selectedID })
                    ?? Puzzle.all.first(where: { $0.id == selectedID }) {
                    ColoringView(puzzle: puzzle, prefersSidePalette: geometry.size.width > geometry.size.height).id(puzzle.id)
                } else {
                    ContentUnavailableView("Choose a picture", systemImage: "square.grid.3x3", description: Text("Your next little masterpiece is waiting."))
                }
            }
        }
        // The canvas uses fixed light paper colors, so its text and controls need a matching appearance.
        .preferredColorScheme(.light)
        .sheet(isPresented: $isCreatingScene) {
            CreateSceneView { scene in
                selectedID = try store.addGeneratedScene(scene).id
            }
        }
        .alert("Delete this scene?", isPresented: Binding(get: { sceneToDelete != nil }, set: {
            if !$0 { sceneToDelete = nil }
        }), presenting: sceneToDelete) { puzzle in
            Button("Delete", role: .destructive) { deleteScene(puzzle) }
            Button("Cancel", role: .cancel) {}
        } message: { puzzle in
            Text("“\(puzzle.title)” and its coloring progress will be removed.")
        }
        .alert("Couldn’t delete scene", isPresented: $showsDeleteError) {
            Button("OK", role: .cancel) {}
        }
    }

    private func deleteScene(_ puzzle: Puzzle) {
        do {
            try store.deleteGeneratedScene(id: puzzle.id)
            if selectedID == puzzle.id {
                selectedID = store.generatedPuzzles.first?.id ?? Puzzle.all.first?.id
            }
        } catch {
            showsDeleteError = true
        }
    }

    private func puzzleRow(_ puzzle: Puzzle) -> some View {
        PuzzleRow(puzzle: puzzle, scene: store.scene(for: puzzle))
            .tag(puzzle.id)
            .listRowBackground(Color.clear)
    }
}

private struct PuzzleRow: View {
    let puzzle: Puzzle
    let scene: PuzzleProgress

    var body: some View {
        let progress = scene.fraction
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
    let prefersSidePalette: Bool
    @EnvironmentObject private var store: PaintStore
    @State private var selectedColor = 1
    @AppStorage("pixelbloom.sound.enabled") private var soundEnabled = true
    @State private var zoom: CGFloat
    private var maximumZoom: CGFloat { puzzle.width > 16 ? 10 : 3 }

    init(puzzle: Puzzle, prefersSidePalette: Bool) {
        self.puzzle = puzzle
        self.prefersSidePalette = prefersSidePalette
        _zoom = State(initialValue: puzzle.width > 16 ? 3 : 1)
    }
    @State private var hint: Int?
    @State private var showReset = false
    @State private var message = "Choose a color, then tap its matching numbers."
    private var isComplete: Bool { store.progress(in: puzzle) == 1 }

    var body: some View {
        GeometryReader { geometry in
            let sidePalette = prefersSidePalette && geometry.size.width >= 520
            let layout = sidePalette ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(spacing: 0))
            VStack(spacing: 0) {
                header(compact: sidePalette)
                layout {
                    canvas(compact: sidePalette)
                        .padding(.horizontal, sidePalette ? 0 : 20)
                    if sidePalette {
                        sidePaletteView
                    } else {
                        bottomPalette
                    }
                }
                .padding(.horizontal, sidePalette ? 12 : 0)
                .padding(.bottom, sidePalette ? 12 : 0)
            }
        }
        .background(paper)
        .navigationTitle("Color by number")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(soundEnabled ? "Mute sounds" : "Enable sounds",
                       systemImage: soundEnabled ? "speaker.wave.2" : "speaker.slash") {
                    soundEnabled.toggle()
                    if !soundEnabled { ColoringAudio.shared.stop() }
                }
                .accessibilityValue(soundEnabled ? "Sounds on" : "Sounds off")
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Start over", systemImage: "arrow.counterclockwise") { showReset = true }
                    .disabled(store.filledCount(in: puzzle) == 0)
            }
        }
        .task { if soundEnabled { ColoringAudio.shared.prepare() } }
        .confirmationDialog("Start this picture over?", isPresented: $showReset, titleVisibility: .visible) {
            Button("Erase this picture’s progress", role: .destructive) {
                store.reset(puzzle)
                hint = nil
                selectedColor = 1
                message = "A fresh canvas. Choose a color to begin."
            }
        } message: { Text("Your other pictures will keep their progress.") }
        .sensoryFeedback(.selection, trigger: store.filledCount(in: puzzle))
    }

    @ViewBuilder
    private func header(compact: Bool) -> some View {
        if compact {
            ViewThatFits(in: .horizontal) {
                HStack {
                    compactTitle
                    Spacer(minLength: 12)
                    zoomControls
                }
                VStack(alignment: .leading, spacing: 4) {
                    compactTitle
                    zoomControls
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        } else {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(puzzle.title).font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text(puzzle.subtitle).font(.subheadline).foregroundStyle(secondaryInk)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    progressPercent.font(.system(.title2, design: .rounded, weight: .semibold))
                    Text("\(store.filledCount(in: puzzle)) / \(puzzle.paintable.count) pixels")
                        .font(.caption).foregroundStyle(secondaryInk)
                }
            }
            .padding(24)

            HStack {
                Label("Drag to color", systemImage: "hand.draw").font(.subheadline)
                Spacer()
                zoomControls
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    private var compactTitle: some View {
        HStack(spacing: 8) {
            Text(puzzle.title).font(.headline).lineLimit(1).truncationMode(.tail)
            progressPercent.font(.caption).foregroundStyle(secondaryInk)
                .accessibilityLabel("Coloring progress")
                .accessibilityValue(store.progress(in: puzzle).formatted(.percent.precision(.fractionLength(0))))
        }
    }

    private var progressPercent: some View {
        Text(store.progress(in: puzzle), format: .percent.precision(.fractionLength(0)))
            .monospacedDigit()
    }

    private var zoomControls: some View {
        HStack {
            Button { zoom = max(1, zoom - 0.5) } label: { Image(systemName: "minus.magnifyingglass") }
                .disabled(zoom <= 1).accessibilityLabel("Zoom out")
            Text("\(Int(zoom * 100))%").font(.caption.monospacedDigit()).frame(minWidth: 40)
            if puzzle.width > 16 {
                Button("Overview") { zoom = 1 }
                    .accessibilityHint("Zoom out to see the whole canvas and your coloring progress")
            }
            Button { zoom = min(maximumZoom, zoom + 0.5) } label: { Image(systemName: "plus.magnifyingglass") }
                .disabled(zoom >= maximumZoom).accessibilityLabel("Zoom in")
        }
        .buttonStyle(.bordered)
        .fixedSize(horizontal: true, vertical: false)
    }

    private func canvas(compact: Bool) -> some View {
        PixelBoard(puzzle: puzzle, scene: store.scene(for: puzzle), selectedColor: selectedColor,
                   zoom: $zoom, maximumZoom: maximumZoom, hint: $hint, margin: compact ? 12 : 24) { indices, interaction in
            let added = store.paint(indices, color: selectedColor, in: puzzle)
            if added > 0 {
                if soundEnabled {
                    ColoringAudio.shared.painted(added: added, remaining: store.remaining(selectedColor, in: puzzle),
                                                 interaction: interaction)
                }
                hint = nil
                message = isComplete ? "Your picture is complete. Beautifully done!" : "Nice! Keep finding \(selectedColor)s."
            } else if indices.count == 1, let index = indices.first, !store.filled(in: puzzle).contains(index) {
                message = "Select color \(puzzle.cells[index]) to fill that square."
            }
        }
        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 24))
    }

    private var hintButton: some View {
        Button { findHint() } label: { Label("Hint", systemImage: "lightbulb") }
            .disabled(isComplete)
    }

    private var feedbackText: some View {
        Text(isComplete ? "Picture complete — take a moment to enjoy it." : message)
            .font(.footnote).foregroundStyle(secondaryInk).accessibilityAddTraits(.updatesFrequently)
    }

    private var sidePaletteView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Colors").font(.subheadline.weight(.semibold))
                Spacer(minLength: 4)
                hintButton.labelStyle(.iconOnly)
            }
            ScrollView(.vertical) {
                LazyVStack(spacing: 4) {
                    ForEach(puzzle.palette) { paint in
                        paletteButton(paint, compact: true)
                    }
                }
                .padding(2)
            }
            feedbackText
        }
        .padding(8)
        .frame(width: 148)
        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
    }

    private var bottomPalette: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                feedbackText
                Spacer()
                hintButton
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(puzzle.palette) { paint in
                        paletteButton(paint, compact: false)
                    }
                }.padding(4)
            }
            Text("One finger to color • Three fingers to move • Pinch to zoom")
                .font(.caption2).foregroundStyle(secondaryInk)
        }
        .padding(24)
    }

    private func paletteButton(_ paint: PaintColor, compact: Bool) -> some View {
        let remaining = store.remaining(paint.id, in: puzzle)
        return Button {
            if soundEnabled { ColoringAudio.shared.selected(from: selectedColor, to: paint.id) }
            selectedColor = paint.id
            hint = nil
            message = remaining == 0 ? "All \(paint.name.lowercased()) squares are done!" : "Find \(remaining) squares marked \(paint.id)."
        } label: {
            let layout = compact ? AnyLayout(HStackLayout(spacing: 6)) : AnyLayout(VStackLayout(spacing: 6))
            layout {
                ZStack {
                    RoundedRectangle(cornerRadius: compact ? 9 : 15).fill(paint.color)
                    // Use dark ink on a white badge so every palette number stays legible.
                    Text(remaining == 0 ? "✓" : "\(paint.id)")
                        .font(compact ? .caption.weight(.semibold) : .headline).foregroundStyle(.black)
                        .frame(width: compact ? 22 : 28, height: compact ? 22 : 28)
                        .background(.white.opacity(0.92), in: Circle())
                }.frame(width: compact ? 34 : 58, height: compact ? 34 : 54)
                VStack(alignment: compact ? .leading : .center, spacing: compact ? 2 : 6) {
                    Text(paint.name).font(.caption2).foregroundStyle(.primary).lineLimit(1)
                    Text("\(remaining) left").font(.caption2).foregroundStyle(secondaryInk)
                }
                .frame(maxWidth: compact ? .infinity : nil, alignment: .leading)
            }
            .padding(compact ? 5 : 6)
            .contentShape(Rectangle())
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
            if soundEnabled { ColoringAudio.shared.selected(from: selectedColor, to: puzzle.cells[next]) }
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
    let scene: PuzzleProgress
    let selectedColor: Int
    @Binding var zoom: CGFloat
    let maximumZoom: CGFloat
    @Binding var hint: Int?
    var margin: CGFloat = 24
    let onPaint: ([Int], PaintInteraction) -> Void
    @GestureState private var pinchMagnification: CGFloat?

    private func zoomLevel(for magnification: CGFloat) -> CGFloat {
        min(maximumZoom, max(1, zoom * magnification))
    }

    var body: some View {
        GeometryReader { geometry in
            let minimumUnit: CGFloat = puzzle.width > 16 ? 4 : 20
            let unit = max(minimumUnit, min((geometry.size.width - 2 * margin) / CGFloat(puzzle.width),
                                           (geometry.size.height - 2 * margin) / CGFloat(puzzle.height))) * zoom
            let boardWidth = CGFloat(puzzle.width) * unit
            let boardHeight = CGFloat(puzzle.height) * unit
            let previewScale = pinchMagnification.map { zoomLevel(for: $0) / zoom } ?? 1
            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    LazyVGrid(columns: (0..<puzzle.tileColumns).map { column in
                        GridItem(.fixed(CGFloat(min(Puzzle.tileSize, puzzle.width - column * Puzzle.tileSize)) * unit), spacing: 0)
                    }, spacing: 0) {
                        ForEach(puzzle.tiles) { tile in
                            PixelTile(puzzle: puzzle, tile: tile, progress: scene.tile(tile),
                                      selectedColor: selectedColor, unit: unit,
                                      hint: hint.flatMap { tile.indices.contains($0) ? $0 : nil },
                                      onPaint: { onPaint([$0], .tap) })
                                .equatable()
                                .id(tile.id)
                        }
                    }
                    .frame(width: boardWidth, height: boardHeight, alignment: .topLeading)
                    .background {
                        CanvasTouchInput(isPinching: pinchMagnification != nil) { start, end, radius, interaction in
                            onPaint(puzzle.strokeIndices(from: start, to: end, unit: unit, contactRadius: radius), interaction)
                        }
                        .allowsHitTesting(false)
                    }
                    // Keep tile sizes fixed until release. The outer frame gives
                    // the scroll view the same extent as the scaled preview.
                    .scaleEffect(previewScale, anchor: .topLeading)
                    .frame(width: boardWidth * previewScale, height: boardHeight * previewScale, alignment: .topLeading)
                    .padding(margin)
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
        .simultaneousGesture(
            MagnifyGesture()
                .updating($pinchMagnification) { value, magnification, _ in
                    magnification = value.magnification
                }
                .onEnded { value in zoom = zoomLevel(for: value.magnification) }
        )
    }
}

// Each tile is one drawing surface, rather than 64 separately laid-out buttons.
// Only the changed tile redraws after painting; offscreen tile rows stay lazy.
private struct PixelTile: View, Equatable {
    let puzzle: Puzzle
    let tile: Puzzle.Tile
    let progress: TileProgress
    let selectedColor: Int
    let unit: CGFloat
    let hint: Int?
    let onPaint: (Int) -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.puzzle.id == rhs.puzzle.id && lhs.tile.id == rhs.tile.id &&
        lhs.progress === rhs.progress && lhs.selectedColor == rhs.selectedColor &&
        lhs.unit == rhs.unit && lhs.hint == rhs.hint
    }

    var body: some View {
        let filled = progress.filled
        Canvas { context, _ in
            var labels: [Int: GraphicsContext.ResolvedText] = [:]
            for index in tile.indices {
                let number = puzzle.cells[index]
                guard number > 0 else { continue }
                let rect = tile.cellRect(index, boardWidth: puzzle.width, unit: unit)
                let paint = puzzle.colorsByNumber[number]?.color ?? .gray
                let isFilled = filled.contains(index)
                context.fill(Path(rect), with: .color(isFilled ? paint : (selectedColor == number ? paint.opacity(0.18) : .white)))
                if !isFilled, unit >= 11 {
                    let label: GraphicsContext.ResolvedText
                    if let cached = labels[number] {
                        label = cached
                    } else {
                        let size = min(22, unit * (number >= 10 ? 0.34 : 0.42))
                        label = context.resolve(Text("\(number)")
                            .font(.system(size: size, weight: selectedColor == number ? .bold : .regular, design: .rounded))
                            .foregroundStyle(selectedColor == number ? Color.primary : secondaryInk))
                        labels[number] = label
                    }
                    context.draw(label, at: CGPoint(x: rect.midX, y: rect.midY))
                }
            }
        }
        .frame(width: CGFloat(tile.width) * unit, height: CGFloat(tile.height) * unit)
        .overlay {
            if unit >= 10 {
                TileGridLines(puzzle: puzzle, tile: tile, unit: unit).equatable()
            }
        }
        .overlay {
            if let hint {
                Path(tile.cellRect(hint, boardWidth: puzzle.width, unit: unit).insetBy(dx: 1.5, dy: 1.5))
                    .stroke(.primary, lineWidth: 3)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
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

// Grid geometry depends on the artwork and cell size, so strokes can reuse it.
private struct TileGridLines: View, Equatable {
    let puzzle: Puzzle
    let tile: Puzzle.Tile
    let unit: CGFloat

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.puzzle.id == rhs.puzzle.id && lhs.tile.id == rhs.tile.id && lhs.unit == rhs.unit
    }

    var body: some View {
        Path { path in
            for index in tile.indices where puzzle.cells[index] > 0 {
                path.addRect(tile.cellRect(index, boardWidth: puzzle.width, unit: unit))
            }
        }
        .stroke(.black.opacity(0.09), lineWidth: 0.5)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private extension Puzzle.Tile {
    func cellRect(_ index: Int, boardWidth: Int, unit: CGFloat) -> CGRect {
        CGRect(x: CGFloat(index % boardWidth - column) * unit,
               y: CGFloat(index / boardWidth - row) * unit,
               width: unit, height: unit)
    }
}


// UIKit exposes touch-count limits, allowing the existing SwiftUI scroll view
// to pan with three fingers while a separate recognizer paints with one.
struct CanvasTouchInput: UIViewRepresentable {
    let isPinching: Bool
    let onStroke: (CGPoint, CGPoint, CGFloat, PaintInteraction) -> Void

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
    var onStroke: (CGPoint, CGPoint, CGFloat, PaintInteraction) -> Void = { _, _, _, _ in }
    var isPinching = false {
        didSet { if isPinching { lastPoint = nil } }
    }
    private(set) weak var connectedScrollView: UIScrollView?
    private var previousMinimumTouches = 1
    private var lastPoint: CGPoint?
    private(set) lazy var paintPan: FingerPaintPan = {
        let gesture = FingerPaintPan(target: self, action: #selector(paintDragged(_:)))
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 1
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()
    private(set) lazy var paintTap: FingerPaintTap = {
        let gesture = FingerPaintTap(target: self, action: #selector(paintTapped(_:)))
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

    @objc private func paintTapped(_ gesture: FingerPaintTap) {
        guard gesture.state == .ended, !isPinching else { return }
        let point = gesture.location(in: self)
        onStroke(point, point, gesture.contactRadius, .tap)
    }

    @objc private func paintDragged(_ gesture: FingerPaintPan) {
        let point = gesture.location(in: self)
        let translation = gesture.translation(in: self)
        handlePaintPan(state: gesture.state, touches: gesture.numberOfTouches, point: point,
                       start: CGPoint(x: point.x - translation.x, y: point.y - translation.y),
                       contactRadius: gesture.contactRadius)
    }

    // Shared with tests to verify that a second touch or cancellation ends the
    // stroke, without joining it to the next one-finger stroke.
    func handlePaintPan(state: UIGestureRecognizer.State, touches: Int, point: CGPoint, start: CGPoint,
                        contactRadius: CGFloat = 0) {
        guard !isPinching, touches <= 1 else { lastPoint = nil; return }
        switch state {
        case .began:
            guard touches == 1 else { return }
            lastPoint = point
            onStroke(start, point, contactRadius, .drag)
        case .changed:
            guard touches == 1, let previous = lastPoint else { return }
            lastPoint = point
            onStroke(previous, point, contactRadius, .drag)
        case .ended:
            if let previous = lastPoint { onStroke(previous, point, contactRadius, .drag) }
            lastPoint = nil
        case .cancelled, .failed:
            lastPoint = nil
        default:
            break
        }
    }
}

// Read contact size from the same touches the system recognizers already track.
// Other input types, including Apple Pencil, keep their precise brush.
final class FingerPaintPan: UIPanGestureRecognizer {
    private(set) var contactRadius: CGFloat = 0

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        contactRadius = touches.first(where: { $0.type == .direct })?.majorRadius ?? 0
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        contactRadius = touches.first(where: { $0.type == .direct })?.majorRadius ?? 0
        super.touchesMoved(touches, with: event)
    }

    override func reset() {
        super.reset()
        contactRadius = 0
    }
}

final class FingerPaintTap: UITapGestureRecognizer {
    private(set) var contactRadius: CGFloat = 0

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        contactRadius = touches.first(where: { $0.type == .direct })?.majorRadius ?? 0
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if let finger = touches.first(where: { $0.type == .direct }) {
            contactRadius = max(contactRadius, finger.majorRadius)
        }
        super.touchesMoved(touches, with: event)
    }

    override func reset() {
        super.reset()
        contactRadius = 0
    }
}
