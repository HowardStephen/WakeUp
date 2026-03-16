import Foundation
import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()
    private var anchor: HKQueryAnchor?

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable else { completion(false); return }
        let typesToRead: Set = [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]
        store.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }

    /// Start observing sleepAnalysis changes and call handler with newly fetched samples (may be called on background threads).
    func startObservingSleep(changesHandler: @escaping ([HKCategorySample]) -> Void) {
        guard isAvailable, let sampleType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        // Observer query to get notified when HealthKit updates sleep data
        let observerQuery = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("HKObserverQuery error: \(error)")
                completionHandler()
                return
            }
            // Fetch recent samples and pass to handler
            self?.fetchRecentSleepSamples { samples in
                changesHandler(samples)
                completionHandler()
            }
        }

        store.execute(observerQuery)

        // Enable background delivery if possible
        store.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
            if let error = error {
                print("enableBackgroundDelivery error: \(error)")
            }
            print("Background delivery enabled: \(success)")
        }

        // Also perform an initial fetch
        fetchRecentSleepSamples { samples in
            changesHandler(samples)
        }
    }

    /// Fetch recent sleep samples (last 7 days by default)
    func fetchRecentSleepSamples(days: Int = 7, completion: @escaping ([HKCategorySample]) -> Void) {
        guard let sampleType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { completion([]); return }
        let cal = Calendar.current
        let from = cal.date(byAdding: .day, value: -days, to: Date()) ?? Date().addingTimeInterval(-7*24*60*60)
        let predicate = HKQuery.predicateForSamples(withStart: from, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 200, sortDescriptors: [sort]) { _, results, error in
            if let error = error {
                print("HKSampleQuery error: \(error)")
                completion([])
                return
            }

            let categorySamples = (results as? [HKCategorySample]) ?? []
            completion(categorySamples)
        }

        store.execute(query)
    }
}
