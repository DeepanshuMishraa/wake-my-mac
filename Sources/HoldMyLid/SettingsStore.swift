import Foundation

@MainActor
final class SettingsStore {
    static let shared = SettingsStore()

    private let key = "HoldMyLid.settings.v1"

    func load() -> HoldSettings {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let settings = try? JSONDecoder().decode(HoldSettings.self, from: data)
        else {
            return HoldSettings()
        }
        return settings
    }

    func save(_ settings: HoldSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
