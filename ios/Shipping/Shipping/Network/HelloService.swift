//
//  HelloService.swift
//  Shipping
//
//  Server check: GET /hello. Always uses the real NetworkLayer, even while
//  the rest of the app runs on the mock.
//

import Foundation

protocol HelloServiceProtocol {
    func hello() async throws -> String
}

final class HelloService: HelloServiceProtocol {
    private let network: NetworkLayerProtocol

    init(network: NetworkLayerProtocol) {
        self.network = network
    }

    func hello() async throws -> String {
        let dto: HelloDTO = try await network.fetchData(endPoint: EndPoint.hello)
        return dto.message
    }
}
