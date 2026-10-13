//
//  KeychainService.swift
//  Shipping
//
//  Single source of truth for the login token. Observable, so the root view
//  swaps Login ↔ Home when it's saved / deleted. One instance, injected from
//  the composition root into LoginViewModel, HomeViewModel and NetworkLayer.
//

import Foundation
import Security

@MainActor
protocol KeychainServiceProtocol: AnyObject {
    var token: String? { get }
    func save(token: String)
    func deleteToken()
}

@MainActor
@Observable
final class KeychainService: KeychainServiceProtocol {
    private(set) var token: String?

    @ObservationIgnored private let service = "corona.shipping"
    @ObservationIgnored private let account = "authToken"

    init() {
        token = readFromKeychain()
    }

    func save(token: String) {
        SecItemDelete(baseQuery as CFDictionary)
        var query = baseQuery
        query[kSecValueData as String] = Data(token.utf8)
        SecItemAdd(query as CFDictionary, nil)
        self.token = token
    }

    func deleteToken() {
        SecItemDelete(baseQuery as CFDictionary)
        token = nil
    }

    private func readFromKeychain() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true
        ]
    }
}
