import AVFoundation
import Foundation

enum PaintInteraction {
    case tap, drag
}

enum ColoringSound: CaseIterable {
    case pixel, swipe, colorCompleted, colorSelected
}

// Decide feedback separately from playback so rapid gestures and milestone
// priority can be tested without an audio device.
struct ColoringSoundFeedback {
    private var lastPaintTime = -Double.infinity
    private var quietUntil = -Double.infinity

    mutating func painted(added: Int, remaining: Int, interaction: PaintInteraction, now: TimeInterval) -> ColoringSound? {
        guard added > 0 else { return nil }
        if remaining == 0 {
            quietUntil = now + 0.35
            return .colorCompleted
        }
        let interval = interaction == .drag ? 0.065 : 0.035
        guard now >= quietUntil, now - lastPaintTime >= interval else { return nil }
        lastPaintTime = now
        return interaction == .drag ? .swipe : .pixel
    }

    func selected(from previous: Int, to next: Int) -> ColoringSound? {
        previous == next ? nil : .colorSelected
    }
}

@MainActor
final class ColoringAudio {
    static let shared = ColoringAudio()
    private var feedback = ColoringSoundFeedback()
    private var players: [ColoringSound: [AVAudioPlayer]] = [:]
    private var isPrepared = false

    func prepare() {
        guard !isPrepared else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // Optional effects respect Silent Mode and mix with the user's music.
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
            if players.isEmpty {
                var prepared: [ColoringSound: [AVAudioPlayer]] = [:]
                for sound in ColoringSound.allCases {
                    let data = ColoringSoundClip.wav(for: sound)
                    prepared[sound] = try (0..<2).map { _ in
                        let player = try AVAudioPlayer(data: data)
                        player.prepareToPlay()
                        return player
                    }
                }
                players = prepared
            }
            isPrepared = true
        } catch {
            // Coloring remains available when audio is interrupted or unavailable.
            isPrepared = false
        }
    }

    func painted(added: Int, remaining: Int, interaction: PaintInteraction) {
        if let sound = feedback.painted(added: added, remaining: remaining, interaction: interaction,
                                        now: ProcessInfo.processInfo.systemUptime) {
            play(sound)
        }
    }

    func selected(from previous: Int, to next: Int) {
        if let sound = feedback.selected(from: previous, to: next) { play(sound) }
    }

    func stop() {
        for player in players.values.flatMap({ $0 }) { player.stop() }
        feedback = ColoringSoundFeedback()
        guard isPrepared else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isPrepared = false
    }

    private func play(_ sound: ColoringSound) {
        prepare()
        guard isPrepared, let voices = players[sound], let player = voices.first(where: { !$0.isPlaying }) ?? voices.first else { return }
        if sound == .colorCompleted {
            for effect in [ColoringSound.pixel, .swipe] {
                players[effect]?.forEach { $0.stop() }
            }
        }
        player.currentTime = 0
        if !player.play() { isPrepared = false }
    }
}

// Short, original PCM effects generated once and cached by the audio player.
// No files, network requests, or synthesis run in the touch-handling hot path.
enum ColoringSoundClip {
    static let sampleRate = 22_050

    static func wav(for sound: ColoringSound) -> Data {
        let duration: Double
        switch sound {
        case .pixel: duration = 0.065
        case .swipe: duration = 0.085
        case .colorCompleted: duration = 0.48
        case .colorSelected: duration = 0.13
        }
        let count = Int(Double(sampleRate) * duration)
        var samples = Data(capacity: count * 2)
        for frame in 0..<count {
            let time = Double(frame) / Double(sampleRate)
            let value: Double
            switch sound {
            case .pixel:
                value = note(time, frequency: 720, length: duration) * 0.24
            case .swipe:
                // A softer, lower wooden tick for continuous strokes.
                value = note(time, frequency: 460, length: duration) * 0.16
            case .colorSelected:
                value = note(time, frequency: 880 + 150 * time / duration, length: duration) * 0.18
            case .colorCompleted:
                value = [(0.0, 660.0), (0.09, 830.61), (0.18, 987.77)].reduce(0.0) { sum, noteSpec in
                    sum + note(time - noteSpec.0, frequency: noteSpec.1, length: 0.30) * 0.15
                }
            }
            append(Int16(max(-1, min(1, value)) * Double(Int16.max)), to: &samples)
        }
        var data = Data("RIFF".utf8)
        append(UInt32(36 + samples.count), to: &data)
        data.append(contentsOf: "WAVEfmt ".utf8)
        append(UInt32(16), to: &data)
        append(UInt16(1), to: &data) // PCM
        append(UInt16(1), to: &data) // mono
        append(UInt32(sampleRate), to: &data)
        append(UInt32(sampleRate * 2), to: &data)
        append(UInt16(2), to: &data)
        append(UInt16(16), to: &data)
        data.append(contentsOf: "data".utf8)
        append(UInt32(samples.count), to: &data)
        data.append(samples)
        return data
    }

    private static func note(_ time: Double, frequency: Double, length: Double) -> Double {
        guard time >= 0, time < length else { return 0 }
        let attack = min(1, time / 0.003)
        let release = min(1, (length - time) / 0.015)
        let envelope = attack * release * exp(-time * 22)
        let fundamental = sin(2 * .pi * frequency * time)
        let overtone = sin(2 * .pi * frequency * 2.01 * time) * 0.23
        return (fundamental + overtone) * envelope
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
    }
}
