import SwiftUI

struct SettingsView: View {
    @StateObject private var connector = HealthKitConnector()

    var body: some View {
        NavigationStack {
            Form {
                Section("Apple Health") {
                    if connector.isAvailable {
                        Button {
                            connector.requestAuthorization()
                        } label: {
                            Label(
                                connector.isAuthorized ? "Connected to Apple Health" : "Connect to Apple Health",
                                systemImage: connector.isAuthorized ? "checkmark.circle.fill" : "heart.fill"
                            )
                        }
                        Text("Completed sessions are saved to Apple Health as Mindful Minutes. Health then makes them available to any other app or device you've connected there, including iHealth.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Health data isn't available on this device.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("A simple Vipassana sitting and walking meditation timer with streaks, a practice calendar, and Apple Health sync.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                connector.refreshStatus()
            }
        }
    }
}

final class HealthKitConnector: ObservableObject {
    @Published var isAuthorized = false
    private let manager = HealthKitManager()

    var isAvailable: Bool { manager.isHealthDataAvailable }

    func requestAuthorization() {
        manager.requestAuthorization { [weak self] success, _ in
            self?.isAuthorized = success
        }
    }

    func refreshStatus() {
        isAuthorized = manager.authorizationStatus() == .sharingAuthorized
    }
}

#Preview {
    SettingsView()
}
