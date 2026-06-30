import Foundation

enum TimerPhase {
    case idle
    case running
    case paused
    case finished
}

final class MeditationTimerEngine: ObservableObject {
    @Published private(set) var phase: TimerPhase = .idle
    @Published private(set) var remainingSeconds: Int = 0

    private(set) var sessionType: SessionType = .sitting
    private(set) var plannedDuration: TimeInterval = 0
    private var startDate: Date?
    private var timer: Timer?

    /// Called with (start, end) when a session completes naturally.
    var onFinish: ((Date, Date) -> Void)?

    func configure(type: SessionType, minutes: Int) {
        sessionType = type
        plannedDuration = TimeInterval(minutes * 60)
        remainingSeconds = minutes * 60
        phase = .idle
        startDate = nil
        timer?.invalidate()
    }

    func start() {
        guard phase == .idle || phase == .paused else { return }
        if phase == .idle {
            startDate = Date()
            BellPlayer.shared.ring()
        }
        phase = .running
        scheduleTimer()
    }

    func pause() {
        guard phase == .running else { return }
        phase = .paused
        timer?.invalidate()
    }

    func reset() {
        timer?.invalidate()
        phase = .idle
        startDate = nil
        remainingSeconds = Int(plannedDuration)
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            finish()
            return
        }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            finish()
        }
    }

    private func finish() {
        timer?.invalidate()
        phase = .finished
        BellPlayer.shared.ring()
        if let start = startDate {
            onFinish?(start, Date())
        }
        startDate = nil
    }

    deinit {
        timer?.invalidate()
    }
}
