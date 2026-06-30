import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var store: SessionStore
    @StateObject private var engine = MeditationTimerEngine()

    @State private var selectedType: SessionType = .sitting
    @State private var selectedMinutes: Int = 20

    private let minuteOptions = [5, 10, 15, 20, 30, 45, 60, 90]

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Picker("Type", selection: $selectedType) {
                    ForEach(SessionType.allCases) { type in
                        Label(type.displayName, systemImage: type.symbolName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(engine.phase != .idle)
                .onChange(of: selectedType) { _, newValue in
                    engine.configure(type: newValue, minutes: selectedMinutes)
                }

                if engine.phase == .idle {
                    Picker("Duration", selection: $selectedMinutes) {
                        ForEach(minuteOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .onChange(of: selectedMinutes) { _, newValue in
                        engine.configure(type: selectedType, minutes: newValue)
                    }
                }

                dial

                controls

                Spacer()
            }
            .padding()
            .navigationTitle("Vipassana Timer")
            .onAppear {
                if engine.plannedDuration == 0 {
                    engine.configure(type: selectedType, minutes: selectedMinutes)
                }
                engine.onFinish = { [weak engine] start, end in
                    guard let engine else { return }
                    store.addSession(
                        type: engine.sessionType,
                        startDate: start,
                        endDate: end,
                        plannedDuration: engine.plannedDuration
                    )
                }
            }
        }
    }

    private var dial: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            Text(timeString)
                .font(.system(size: 48, weight: .light, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: 220, height: 220)
        .padding()
    }

    private var progress: Double {
        guard engine.plannedDuration > 0 else { return 0 }
        return 1 - (Double(engine.remainingSeconds) / engine.plannedDuration)
    }

    private var timeString: String {
        let minutes = engine.remainingSeconds / 60
        let seconds = engine.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    @ViewBuilder
    private var controls: some View {
        switch engine.phase {
        case .idle:
            Button(action: engine.start) {
                Label("Start", systemImage: "play.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

        case .running:
            HStack(spacing: 16) {
                Button(action: engine.pause) {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(role: .destructive, action: engine.reset) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

        case .paused:
            HStack(spacing: 16) {
                Button(action: engine.start) {
                    Label("Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(role: .destructive, action: engine.reset) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

        case .finished:
            VStack(spacing: 12) {
                Label("Session complete", systemImage: "checkmark.circle.fill")
                    .font(.title3.bold())
                    .foregroundStyle(.green)
                Button("New Session") {
                    engine.configure(type: selectedType, minutes: selectedMinutes)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

#Preview {
    TimerView()
        .environmentObject(SessionStore())
}
