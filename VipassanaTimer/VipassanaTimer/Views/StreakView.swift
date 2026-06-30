import SwiftUI

struct StreakView: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        statCard(title: "Current Streak", value: "\(store.currentStreak)", icon: "flame.fill", color: .orange)
                        statCard(title: "Longest Streak", value: "\(store.longestStreak)", icon: "trophy.fill", color: .yellow)
                    }

                    statCard(title: "Total Sessions", value: "\(store.sessions.count)", icon: "checkmark.seal.fill", color: .green)

                    CalendarView()
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    StreakView()
        .environmentObject(SessionStore())
}
