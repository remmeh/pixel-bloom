import ImageIO
import SwiftUI
import ImagePlayground

struct GeneratedScene: Codable, Sendable {
    static let size = 64
    let id: UUID
    let title: String
    let rows: [String]
    let colors: [UInt32]
    var puzzleID: String { "generated-\(id.uuidString)" }

    func puzzle() -> Puzzle? {
        guard !title.isEmpty, (1...12).contains(colors.count),
              rows.count == Self.size,
              rows.allSatisfy({ row in
                  row.count == Self.size && row.allSatisfy {
                      guard let number = Int(String($0), radix: 36) else { return false }
                      return (1...colors.count).contains(number)
                  }
              }) else { return nil }

        return Puzzle(id: puzzleID, title: title, subtitle: "A scene you created.",
                      symbol: "sparkles", rows: rows, palette: colors.enumerated().map { index, color in
            PaintColor(id: index + 1, name: "Color \(index + 1)", hex: color)
        })
    }

    func named(_ name: String) -> Self {
        let title = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        return Self(id: id, title: title.isEmpty ? "Created scene" : title, rows: rows, colors: colors)
    }

    static func make(from data: Data) throws -> Self {
        let size = Self.size
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 256
              ] as CFDictionary),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: size, height: size,
                                      bitsPerComponent: 8, bytesPerRow: size * 4, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
                                                  CGBitmapInfo.byteOrder32Big.rawValue),
              let buffer = context.data else { throw GeneratedSceneError.unreadableImage }

        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        let scale = min(CGFloat(size) / CGFloat(image.width), CGFloat(size) / CGFloat(image.height))
        let width = CGFloat(image.width) * scale
        let height = CGFloat(image.height) * scale
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: (CGFloat(size) - width) / 2, y: (CGFloat(size) - height) / 2,
                                       width: width, height: height))

        let bytes = buffer.assumingMemoryBound(to: UInt8.self)
        let pixels = (0..<(size * size)).map { index in
            let offset = index * 4
            return RGB(red: Int(bytes[offset]), green: Int(bytes[offset + 1]), blue: Int(bytes[offset + 2]))
        }

        // Split the sampled colors into compact groups, then assign each pixel
        // to the nearest swatch. The result uses the regular color-by-number grid.
        var groups = [ColorGroup(pixels: pixels)]
        while groups.count < 12,
              let index = groups.indices.max(by: { groups[$0].splitPriority < groups[$1].splitPriority }),
              groups[index].splitPriority > 0 {
            let group = groups.remove(at: index)
            let sorted = group.pixels.sorted { $0.component(group.channel) < $1.component(group.channel) }
            let middle = sorted.count / 2
            groups.append(ColorGroup(pixels: Array(sorted[..<middle])))
            groups.append(ColorGroup(pixels: Array(sorted[middle...])))
        }

        let swatches = groups.map(\.average)
        var colors: [UInt32] = []
        var numbers: [UInt32: Int] = [:]
        var rows: [String] = []
        for row in 0..<size {
            var line = ""
            for column in 0..<size {
                let pixel = pixels[row * size + column]
                let nearest = swatches.min(by: { $0.distance(to: pixel) < $1.distance(to: pixel) })!.hex
                if numbers[nearest] == nil {
                    colors.append(nearest)
                    numbers[nearest] = colors.count
                }
                line += String(numbers[nearest]!, radix: 36, uppercase: true)
            }
            rows.append(line)
        }
        return Self(id: UUID(), title: "Created scene", rows: rows, colors: colors)
    }
}

private struct RGB {
    let red: Int
    let green: Int
    let blue: Int

    var hex: UInt32 { UInt32(red << 16 | green << 8 | blue) }

    func component(_ channel: Int) -> Int {
        switch channel {
        case 0: return red
        case 1: return green
        default: return blue
        }
    }

    func distance(to other: Self) -> Int {
        let dr = red - other.red
        let dg = green - other.green
        let db = blue - other.blue
        return 2 * dr * dr + 3 * dg * dg + db * db
    }
}

private struct ColorGroup {
    let pixels: [RGB]
    let channel: Int
    let splitPriority: Int

    init(pixels: [RGB]) {
        self.pixels = pixels
        let ranges = (0..<3).map { channel in
            let components = pixels.map { $0.component(channel) }
            return components.max()! - components.min()!
        }
        channel = ranges.indices.max(by: { ranges[$0] < ranges[$1] })!
        splitPriority = ranges[channel] * pixels.count
    }

    var average: RGB {
        RGB(red: pixels.reduce(0) { $0 + $1.red } / pixels.count,
            green: pixels.reduce(0) { $0 + $1.green } / pixels.count,
            blue: pixels.reduce(0) { $0 + $1.blue } / pixels.count)
    }
}

enum GeneratedSceneError: LocalizedError {
    case unreadableImage, invalidScene

    var errorDescription: String? {
        switch self {
        case .unreadableImage: return "PixelBloom couldn’t read the artwork. Try choosing another image."
        case .invalidScene: return "PixelBloom couldn’t save this scene. Try generating it again."
        }
    }
}

struct CreateSceneView: View {
    let onSave: (GeneratedScene) throws -> Void

    var body: some View {
        NavigationStack {
            if #available(iOS 18.4, *) {
                ImagePlaygroundForm(onSave: onSave)
            } else {
                ContentUnavailableView("Image Playground unavailable", systemImage: "sparkles",
                                       description: Text("Creating scenes requires iPadOS 18.4 or later and Apple Intelligence."))
                    .modifier(CreateSceneNavigation())
            }
        }
    }
}

@available(iOS 18.4, *)
private struct ImagePlaygroundForm: View {
    let onSave: (GeneratedScene) throws -> Void
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var draft: GeneratedScene?
    @State private var title = ""
    @State private var showPlayground = false
    @State private var converting = false
    @State private var errorMessage: String?

    private var prompt: String { description.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Group {
            if supportsImagePlayground || draft != nil || converting {
                Form {
                    if let draft {
                        Section("Name your new scene") {
                            TextField("Created scene", text: $title)
                        }
                        Button("Save scene") {
                            do {
                                try onSave(draft.named(title))
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                        Button("Choose different artwork") {
                            self.draft = nil
                            title = ""
                        }
                    } else {
                        Section {
                            TextField("A sleepy fox in a field of daisies", text: $description, axis: .vertical)
                                .lineLimit(3...6)
                                .disabled(converting)
                        } header: {
                            Text("Describe your scene")
                        } footer: {
                            Text("Choose an image in Image Playground to turn it into a 64×64 coloring scene.")
                        }
                        Button {
                            showPlayground = true
                        } label: {
                            Label("Generate artwork", systemImage: "sparkles")
                        }
                        .disabled(prompt.isEmpty || converting)
                        if converting { ProgressView("Creating your coloring scene…") }
                    }
                }
                .imagePlaygroundGenerationStyle(.illustration, in: [.illustration, .animation])
                .imagePlaygroundSheet(isPresented: $showPlayground, concepts: [.text(String(prompt.prefix(500)))],
                                      onCompletion: convert)
            } else {
                ContentUnavailableView("Image Playground unavailable", systemImage: "sparkles",
                                       description: Text("Turn on Apple Intelligence on a supported iPad to generate artwork."))
            }
        }
        .modifier(CreateSceneNavigation(busy: converting))
        .interactiveDismissDisabled(converting)
        .alert("Couldn’t create scene", isPresented: Binding(get: { errorMessage != nil }, set: {
            if !$0 { errorMessage = nil }
        })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func convert(_ url: URL) {
        // The system owns the temporary URL. Read it before the sheet dismisses.
        guard let data = try? Data(contentsOf: url) else {
            errorMessage = GeneratedSceneError.unreadableImage.localizedDescription
            return
        }
        let scenePrompt = prompt
        converting = true
        Task {
            defer { converting = false }
            do {
                let scene = try await Task.detached(priority: .userInitiated) {
                    try GeneratedScene.make(from: data)
                }.value
                title = scene.named(scenePrompt).title
                draft = scene
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct CreateSceneNavigation: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    var busy = false

    func body(content: Content) -> some View {
        content
            .navigationTitle("Create a scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }.disabled(busy)
                }
            }
    }
}
