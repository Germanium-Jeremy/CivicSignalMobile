import Foundation

struct TokenManager {
    private enum Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userData = "user_data"
    }

    static func saveTokens(accessToken: String, refreshToken: String) {
        UserDefaults.standard.set(accessToken, forKey: Keys.accessToken)
        UserDefaults.standard.set(refreshToken, forKey: Keys.refreshToken)
    }

    static var accessToken: String? {
        UserDefaults.standard.string(forKey: Keys.accessToken)
    }

    static var refreshToken: String? {
        UserDefaults.standard.string(forKey: Keys.refreshToken)
    }

    static func clearTokens() {
        UserDefaults.standard.removeObject(forKey: Keys.accessToken)
        UserDefaults.standard.removeObject(forKey: Keys.refreshToken)
        UserDefaults.standard.removeObject(forKey: Keys.userData)
    }

    // Generic user data – same idea as AsyncStorage JSON
    static func saveUserData<T: Encodable>(_ data: T) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(data) {
            UserDefaults.standard.set(encoded, forKey: Keys.userData)
        }
    }

    static func getUserData<T: Decodable>(_ type: T.Type) -> T? {
        guard let stored = UserDefaults.standard.data(forKey: Keys.userData) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: stored)
    }
}
