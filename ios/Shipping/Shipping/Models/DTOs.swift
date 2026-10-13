//
//  DTOs.swift
//  Shipping
//
//  Mirror the API contract in CLAUDE.md exactly (camelCase keys, raw strings).
//

import Foundation

// MARK: - Hello

struct HelloDTO: Decodable {
    let message: String
}

// MARK: - Login

struct LoginBody: Encodable {
    let username: String
    let password: String
}

struct LoginResponseDTO: Decodable {
    let token: String
}

// MARK: - Shipments

struct ShipmentsResponseDTO: Decodable {
    let shipments: [ShipmentSummaryDTO]
}

// Used by list, create (201) and approve (200) responses.
struct ShipmentSummaryDTO: Decodable {
    let requestId: String
    let status: String
}

struct DimensionsDTO: Codable {
    let lengthCm: Double
    let widthCm: Double
    let heightCm: Double
}

struct CreateShipmentBody: Encodable {
    let quantity: Int
    let weightKg: Double
    let dimensions: DimensionsDTO
    let packageType: String
    let deliveryDate: String
    let shippingMode: String
    let pickupAddress: String
    let deliveryAddress: String
    let priority: String
    let temperatureControl: Bool
    let customsBy: String
    let insuranceBy: String
    let localTruckingBy: String
    let incoterms: String
}

struct ShipmentDetailsDTO: Decodable {
    let requestId: String
    let status: String
    let options: [OptionDTO]
}

struct OptionDTO: Decodable {
    let optionId: String
    let mode: String
    let price: Double
    let estimatedArrival: String
    let containerType: String
}

struct ApproveBody: Encodable {
    let optionId: String
}

// MARK: - Errors (422)

struct ValidationErrorsDTO: Decodable {
    let errors: [FieldErrorDTO]
}

struct FieldErrorDTO: Decodable {
    let field: String
    let message: String
}

// MARK: - Devices

struct DeviceBody: Encodable {
    let deviceToken: String
}

struct DeviceResponseDTO: Decodable {
    let id: String
}
