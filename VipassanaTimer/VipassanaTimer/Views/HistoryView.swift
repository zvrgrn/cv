import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.sessions) { session in
                    HStack {
                        Image(systemName: session.type.symbolName)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading) {
                            Text(session.type.displayName)
                                .font(.headline)
                            Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(session.actualDuration / 60)) min")
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if store.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions Yet",
                        systemImage: "timer",
                        description: Text("Complete a meditation session to see it here.")
                    )
                }
            }
            .navigationTitle("History")
            .toolbar {
                EditButton()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            store.deleteSession(store.sessions[index])
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(SessionStore())
}
