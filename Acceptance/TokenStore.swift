import Foundation
import Security

final class TokenStore {
    private let accessKey = "auth.access"
    private let refreshKey = "auth.refresh"

    var accessToken: String? {
        get { read(key: accessKey) }
        set { newValue == nil ? delete(key: accessKey) : save(key: accessKey, value: newValue!) }
    }
    var refreshToken: String? {
        get { read(key: refreshKey) }
        set { newValue == nil ? delete(key: refreshKey) : save(key: refreshKey, value: newValue!) }
    }
    func clear() { delete(key: accessKey); delete(key: refreshKey) }

    private func save(key: String, value: String) {
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: "AuthUIKitReady",
                                   kSecAttrAccount as String: key]
        SecItemDelete(base as CFDictionary)
        var attrs = base; attrs[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(attrs as CFDictionary, nil)
    }
    private func read(key: String) -> String? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: "AuthUIKitReady",
                                kSecAttrAccount as String: key,
                                kSecReturnData as String: true,
                                kSecMatchLimit as String: kSecMatchLimitOne]
        var ref: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &ref) == errSecSuccess,
              let data = ref as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    private func delete(key: String) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: "AuthUIKitReady",
                                kSecAttrAccount as String: key]
        SecItemDelete(q as CFDictionary)
    }
}
