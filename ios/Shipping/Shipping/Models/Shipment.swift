//
//  Shipment.swift
//  Shipping
//
//  App-owned domain models. Raw values match the API strings.
//

import Foundation

enum ShipmentStatus: String {
    case preparingOptions = "preparing_options"
    case optionsReady = "options_ready"
    case approved
    case inTransit = "in_transit"
    case unknown
}

enum PackageType: String, CaseIterable {
    case bottles, cans, kegs, pallets
}

enum ShippingMode: String, CaseIterable {
    case sea, air
}

enum Priority: String, CaseIterable {
    case lowestPrice, fastest
}

enum Party: String, CaseIterable {
    case buyer, seller
}

enum Incoterms: String, CaseIterable {
    case exw = "EXW"
    case fca = "FCA"
    case fob = "FOB"
    case cif = "CIF"
    case dap = "DAP"
    case ddp = "DDP"
}

enum ContainerType: String {
    case twentyFt = "20ft"
    case fortyFt = "40ft"
    case fortyFtReefer = "40ft_reefer"
    case uld
}

struct Shipment: Identifiable, Equatable {
    let id: String
    let status: ShipmentStatus
}

struct ShippingOption: Identifiable, Equatable {
    let id: String
    let mode: ShippingMode
    let price: Double
    let estimatedArrival: Date
    let containerType: ContainerType
}

struct ShipmentDetails: Equatable {
    let id: String
    let status: ShipmentStatus
    let options: [ShippingOption]
}

// What Submit sends — built only from a validated form.
struct ShipmentRequest: Equatable {
    let quantity: Int
    let weightKg: Double
    let lengthCm: Double
    let widthCm: Double
    let heightCm: Double
    let packageType: PackageType
    let deliveryDate: Date
    let shippingMode: ShippingMode
    let pickupAddress: String
    let deliveryAddress: String
    let priority: Priority
    let temperatureControl: Bool
    let customsBy: Party
    let insuranceBy: Party
    let localTruckingBy: Party
    let incoterms: Incoterms
}

// `field` is the camelCase key from the request, same as the 422 body.
// nonisolated: carried inside NetworkError, which must be usable off the main actor.
nonisolated struct FieldError: Equatable, Sendable {
    let field: String
    let message: String
}
