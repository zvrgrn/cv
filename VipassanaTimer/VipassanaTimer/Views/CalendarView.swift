import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: SessionStore
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 16) {
            header

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(for: date)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }

            Divider()

            sessionsForSelectedDate
        }
    }

    private var header: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthYearString)
                .font(.headline)
            Spacer()
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasSession = store.hasSession(on: date)
        let isToday = calendar.isDateInToday(date)

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.callout)
                    .fontWeight(isToday ? .bold : .regular)
                Circle()
                    .fill(hasSession ? Color.accentColor : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var sessionsForSelectedDate: some View {
        let sessions = store.sessions.filter { calendar.isDate($0.startDate, inSameDayAs: selectedDate) }
        if sessions.isEmpty {
            Text("No sessions on \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(sessions) { session in
                    HStack {
                        Image(systemName: session.type.symbolName)
                        Text(session.type.displayName)
                        Spacer()
                        Text("\(Int(session.actualDuration / 60)) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private var daysInGrid: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        var date = monthInterval.start
        while date < monthInterval.end {
            days.append(date)
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return days
    }
}

#Preview {
    CalendarView()
        .environmentObject(SessionStore())
        .padding()
}
