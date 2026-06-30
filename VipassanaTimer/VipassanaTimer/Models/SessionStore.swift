import Foundation
import Combine

final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [MeditationSession] = []

    private let fileURL: URL
    private let healthKitManager: HealthKitManager

    init(healthKitManager: HealthKitManager = HealthKitManager()) {
        self.healthKitManager = healthKitManager
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("sessions.json")
        load()
    }

    func addSession(type: SessionType, startDate: Date, endDate: Date, plannedDuration: TimeInterval) {
        let session = MeditationSession(type: type, startDate: startDate, endDate: endDate, plannedDuration: plannedDuration)
        sessions.insert(session, at: 0)
        sessions.sort { $0.startDate > $1.startDate }
        save()
        healthKitManager.saveMindfulSession(start: startDate, end: endDate) { _ in }
    }

    func deleteSession(_ session: MeditationSession) {
        sessions.removeAll { $0.id == session.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([MeditationSession].self, from: data) {
            sessions = decoded.sorted { $0.startDate > $1.startDate }
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Derived stats

    func hasSession(on date: Date) -> Bool {
        let calendar = Calendar.current
        return sessions.contains { calendar.isDate($0.startDate, inSameDayAs: date) }
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: Date())

        if !hasSession(on: day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day), hasSession(on: yesterday) else {
                return 0
            }
            day = yesterday
        }

        var streak = 0
        while hasSession(on: day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.startDate) }).sorted()
        guard !uniqueDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for i in 1..<uniqueDays.count {
            let diff = calendar.dateComponents([.day], from: uniqueDays[i - 1], to: uniqueDays[i]).day ?? 0
            current = diff == 1 ? current + 1 : 1
            longest = max(longest, current)
        }
        return longest
    }
}
