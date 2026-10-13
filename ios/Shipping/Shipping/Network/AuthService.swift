//
//  AuthService.swift
//  Shipping
//
//  Calls login and returns the token. LoginViewModel saves it.
//

import Foundation

protocol AuthServiceProtocol {
    func login(username: String, password: String) async throws -> String
}

final class AuthService: AuthServiceProtocol {
    private let network: NetworkLayerProtocol

    init(network: NetworkLayerProtocol) {
        self.network = network
    }

    func login(username: String, password: String) async throws -> String {
        let response: LoginResponseDTO = try await network.fetchData(
            endPoint: EndPoint.login(username: username, password: password))
        return response.token
    }
}
