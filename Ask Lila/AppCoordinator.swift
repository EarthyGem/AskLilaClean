import SwiftEphemeris
import Foundation


class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let chartKey = "savedChartCake"
    
    func saveChart(_ chartCake: ChartCake) {
        print("🔍 DEBUG: Saving chart to UserDefaults")

        if chartCake.natal.latitude.isNaN || chartCake.natal.longitude.isNaN {
            print("🚨 ERROR: ChartCake contains NaN values. Latitude: \(chartCake.natal.latitude), Longitude: \(chartCake.natal.longitude)")
            return
        }

        let chartData: [String: Any] = [
            "birthDate": chartCake.natal.birthDate.timeIntervalSince1970,
            "latitude": chartCake.natal.latitude,
            "longitude": chartCake.natal.longitude,
            "name": chartCake.name ?? ""
        ]

        UserDefaults.standard.set(chartData, forKey: chartKey)
        UserDefaults.standard.synchronize()

        let confirm = UserDefaults.standard.dictionary(forKey: chartKey)
        print("✅ DEBUG: Chart saved with name: \(chartCake.name ?? "Unknown")")
        print("🧪 DEBUG: Raw saved data: \(confirm ?? [:])")
    }

    func loadChart() -> ChartCake? {
        print("🔍 DEBUG: Loading chart from UserDefaults")

        guard let chartData = UserDefaults.standard.dictionary(forKey: chartKey),
              let birthDateInterval = chartData["birthDate"] as? TimeInterval,
              let latitude = chartData["latitude"] as? Double,
              let longitude = chartData["longitude"] as? Double else {
            print("⚠️ DEBUG: Failed to load chart data from UserDefaults — got: \(UserDefaults.standard.dictionary(forKey: chartKey) ?? [:])")
            return nil
        }

        let name = chartData["name"] as? String ?? "Unknown"
        let birthDate = Date(timeIntervalSince1970: birthDateInterval)

        print("✅ DEBUG: Loaded chart for: \(name)")
        return ChartCake(birthDate: birthDate, latitude: latitude, longitude: longitude, name: name)
    }

}
