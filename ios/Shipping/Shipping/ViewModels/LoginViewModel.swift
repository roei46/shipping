//
//  LoginViewModel.swift
//  Shipping
//
//  Logs in and saves the token. Saving it flips the root view to Home.
//

import Foundation

@MainActor
@Observable
final class LoginViewModel {
    var username = ""
    var password = ""
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let auth: AuthServiceProtocol
    private let keychain: KeychainServiceProtocol
    private let hello: HelloServiceProtocol

    var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !isLoading
    }

    init(auth: AuthServiceProtocol, keychain: KeychainServiceProtocol, hello: HelloServiceProtocol) {
        self.auth = auth
        self.keychain = keychain
        self.hello = hello
    }

    // Server check — runs once when the screen starts.
    func sayHello() async {
        do {
            print("hello:", try await hello.hello())
        } catch {
            print("hello failed:", error)
        }
    }

    func login() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let token = try await auth.login(username: username.trimmingCharacters(in: .whitespaces),
                                             password: password)
            keychain.save(token: token)
            password = ""
        } catch NetworkError.unauthorized {
            errorMessage = "Wrong username or password"
        } catch {
            errorMessage = "Couldn't log in. Try again."
        }
    }
}
