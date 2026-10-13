//
//  MockServices.swift
//  Shipping
//
//  Fake server for running the app before the backend exists, and for
//  previews. Behaves like the contract: 404 / 409, and a new shipment flips
//  from preparing_options to options_ready a few seconds after Submit.
//

import Foundation

@MainActor
@Observable
final class InMemoryKeychainService: KeychainServiceProtocol {
    private(set) var token: String?

    init(token: String? = nil) {
        self.token = token
    }

    func save(token: String) {
        self.token = token
    }

    func deleteToken() {
        token = nil
    }
}

// For previews only — the app always calls the real server for hello.
final class MockHelloService: HelloServiceProtocol {
    func hello() async throws -> String {
        "hello world (mock)"
    }
}

final class MockAuthService: AuthServiceProtocol {
    // Any username works. Password "wrong" simulates a 401.
    func login(username: String, password: String) async throws -> String {
        try await Task.sleep(for: .milliseconds(400))
        guard password != "wrong" else { throw NetworkError.unauthorized }
        return "mock-token"
    }
}

final class MockShipmentService: ShipmentServiceProtocol {
    static let readyShipmentId = "3f9a2c10-7b1e-4c55-9d1a-0a7e2b6c1042"

    private struct Record {
        var shipment: Shipment
        var options: [ShippingOption]
        var readyAt: Date?
    }

    private var records: [Record]
    private let latency: Duration
    private let secondsUntilReady: TimeInterval

    init(latency: Duration = .milliseconds(400), secondsUntilReady: TimeInterval = 5) {
        self.latency = latency
        self.secondsUntilReady = secondsUntilReady
        self.records = Self.seed()
    }

    func fetchShipments() async throws -> [Shipment] {
        try await Task.sleep(for: latency)
        promoteReadyShipments()
        return records.map(\.shipment)
    }

    func create(_ request: ShipmentRequest) async throws -> Shipment {
        try await Task.sleep(for: latency)
        let shipment = Shipment(id: UUID().uuidString.lowercased(), status: .preparingOptions)
        records.insert(Record(shipment: shipment,
                              options: Self.makeOptions(reefer: request.temperatureControl),
                              readyAt: Date().addingTimeInterval(secondsUntilReady)),
                       at: 0)
        return shipment
    }

    func fetchShipment(id: String) async throws -> ShipmentDetails {
        try await Task.sleep(for: latency)
        promoteReadyShipments()
        guard let record = records.first(where: { $0.shipment.id == id }) else {
            throw NetworkError.notFound
        }
        let options = record.shipment.status == .preparingOptions ? [] : record.options
        return ShipmentDetails(id: id, status: record.shipment.status, options: options)
    }

    func approve(id: String, optionId: String) async throws -> Shipment {
        try await Task.sleep(for: latency)
        guard let index = records.firstIndex(where: { $0.shipment.id == id }) else {
            throw NetworkError.notFound
        }
        guard records[index].shipment.status == .optionsReady else {
            throw NetworkError.conflict
        }
        guard records[index].options.contains(where: { $0.id == optionId }) else {
            throw NetworkError.notFound
        }
        let approved = Shipment(id: id, status: .approved)
        records[index].shipment = approved
        return approved
    }

    func registerDevice(token: String) async throws {}

    // MARK: - Fake data

    private func promoteReadyShipments() {
        let now = Date()
        for index in records.indices {
            guard records[index].shipment.status == .preparingOptions,
                  let readyAt = records[index].readyAt, readyAt <= now else { continue }
            records[index].shipment = Shipment(id: records[index].shipment.id, status: .optionsReady)
        }
    }

    private static func makeOptions(reefer: Bool) -> [ShippingOption] {
        let today = Calendar.current.startOfDay(for: Date())
        return [
            ShippingOption(id: UUID().uuidString.lowercased(),
                           mode: .sea,
                           price: reefer ? 6200 : 4800,
                           estimatedArrival: today.addingTimeInterval(36 * 86_400),
                           containerType: reefer ? .fortyFtReefer : .fortyFt),
            ShippingOption(id: UUID().uuidString.lowercased(),
                           mode: .air,
                           price: 14_200,
                           estimatedArrival: today.addingTimeInterval(15 * 86_400),
                           containerType: .uld)
        ]
    }

    // Matches the PDF feed: ready / preparing / approved / in transit.
    private static func seed() -> [Record] {
        [
            Record(shipment: Shipment(id: readyShipmentId, status: .optionsReady),
                   options: makeOptions(reefer: false), readyAt: nil),
            Record(shipment: Shipment(id: "9c1d4e77-2a3b-4f60-8e21-5b9f0d7a1039", status: .preparingOptions),
                   options: makeOptions(reefer: true), readyAt: nil),
            Record(shipment: Shipment(id: "b20e8f31-6c4d-4a1e-9f73-2d8c5e0b1031", status: .approved),
                   options: [], readyAt: nil),
            Record(shipment: Shipment(id: "e7a35b92-1f0c-4d8e-a6b4-7c2e9f3d1024", status: .inTransit),
                   options: [], readyAt: nil)
        ]
    }
}
