//
//  ShipmentService.swift
//  Shipping
//
//  Typed calls for the shipment endpoints. Maps DTOs to domain models.
//

import Foundation

protocol ShipmentServiceProtocol {
    func fetchShipments() async throws -> [Shipment]
    func create(_ request: ShipmentRequest) async throws -> Shipment
    func fetchShipment(id: String) async throws -> ShipmentDetails
    func approve(id: String, optionId: String) async throws -> Shipment
    func registerDevice(token: String) async throws
}

final class ShipmentService: ShipmentServiceProtocol {
    private let network: NetworkLayerProtocol

    init(network: NetworkLayerProtocol) {
        self.network = network
    }

    func fetchShipments() async throws -> [Shipment] {
        let dto: ShipmentsResponseDTO = try await network.fetchData(endPoint: EndPoint.shipments)
        return dto.shipments.map(Shipment.init(dto:))
    }

    func create(_ request: ShipmentRequest) async throws -> Shipment {
        let dto: ShipmentSummaryDTO = try await network.fetchData(endPoint: EndPoint.createShipment(request: request))
        return Shipment(dto: dto)
    }

    func fetchShipment(id: String) async throws -> ShipmentDetails {
        let dto: ShipmentDetailsDTO = try await network.fetchData(endPoint: EndPoint.shipment(id: id))
        return try ShipmentDetails(dto: dto)
    }

    func approve(id: String, optionId: String) async throws -> Shipment {
        let dto: ShipmentSummaryDTO = try await network.fetchData(endPoint: EndPoint.approve(id: id, optionId: optionId))
        return Shipment(dto: dto)
    }

    func registerDevice(token: String) async throws {
        let _: DeviceResponseDTO = try await network.fetchData(endPoint: EndPoint.registerDevice(deviceToken: token))
    }
}
