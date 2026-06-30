import Foundation
import HealthKit

final class HealthKitManager {
    private let healthStore = HKHealthStore()

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func authorizationStatus() -> HKAuthorizationStatus? {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return nil }
        return healthStore.authorizationStatus(for: mindfulType)
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard isHealthDataAvailable, let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            completion(false, nil)
            return
        }
        healthStore.requestAuthorization(toShare: [mindfulType], read: [mindfulType]) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    /// Writes a completed session to Apple Health as a Mindful Minutes sample.
    /// The Health app then makes this available to any other app or device (including
    /// third-party trackers such as iHealth) that the user has connected through Health.
    func saveMindfulSession(start: Date, end: Date, completion: @escaping (Bool) -> Void) {
        guard isHealthDataAvailable, let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            completion(false)
            return
        }
        guard healthStore.authorizationStatus(for: mindfulType) == .sharingAuthorized else {
            completion(false)
            return
        }
        let sample = HKCategorySample(type: mindfulType, value: 0, start: start, end: end)
        healthStore.save(sample) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
