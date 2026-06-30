import Foundation

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case sitting
    case walking

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sitting: return "Sitting"
        case .walking: return "Walking"
        }
    }

    var symbolName: String {
        switch self {
        case .sitting: return "figure.seated.side"
        case .walking: return "figure.walk"
        }
    }
}

struct MeditationSession: Identifiable, Codable, Equatable {
    let id: UUID
    let type: SessionType
    let startDate: Date
    let endDate: Date
    let plannedDuration: TimeInterval

    var actualDuration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    init(id: UUID = UUID(), type: SessionType, startDate: Date, endDate: Date, plannedDuration: TimeInterval) {
        self.id = id
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.plannedDuration = plannedDuration
    }
}
