import AVFoundation

/// Synthesizes a simple bell tone in code, so the app needs no bundled audio file.
final class BellPlayer {
    static let shared = BellPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let buffer: AVAudioPCMBuffer?

    private init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        buffer = Self.makeBellBuffer(format: format)

        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func ring() {
        guard let buffer else { return }
        do {
            if !engine.isRunning {
                try engine.start()
            }
            player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            player.play()
        } catch {
            // Audio is a nicety here; a failure to play shouldn't interrupt the timer.
        }
    }

    private static func makeBellBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration = 3.0
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        let partials: [Double] = [220.0, 330.0, 440.0]
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let envelope = exp(-t * 2.0)
            let sample = partials.reduce(0.0) { $0 + sin(2.0 * .pi * $1 * t) }
            channel[frame] = Float(sample / Double(partials.count) * envelope * 0.5)
        }
        return buffer
    }
}
