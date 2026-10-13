//
//  ShipmentFormatter.swift
//  Shipping
//
//  Domain values → display strings. No logic beyond formatting.
//

import Foundation

enum StatusTone: Equatable {
    case success, pending, info, neutral
}

// Names shown in pickers and labels.
protocol DisplayNamed {
    var displayName: String { get }
}

extension PackageType: DisplayNamed {
    var displayName: String {
        switch self {
        case .bottles: "Bottles"
        case .cans: "Cans"
        case .kegs: "Kegs"
        case .pallets: "Pallets"
        }
    }
}

extension ShippingMode: DisplayNamed {
    var displayName: String {
        switch self {
        case .sea: "Sea"
        case .air: "Air"
        }
    }
}

extension Priority: DisplayNamed {
    var displayName: String {
        switch self {
        case .lowestPrice: "Lowest price"
        case .fastest: "Fastest"
        }
    }
}

extension Party: DisplayNamed {
    var displayName: String {
        switch self {
        case .buyer: "Buyer"
        case .seller: "Seller"
        }
    }
}

extension Incoterms: DisplayNamed {
    var displayName: String { rawValue }
}

extension ContainerType: DisplayNamed {
    var displayName: String {
        switch self {
        case .twentyFt: "20ft"
        case .fortyFt: "40ft"
        case .fortyFtReefer: "40ft reefer"
        case .uld: "ULD pallets"
        }
    }
}

struct ShipmentFormatter {
    private let arrivalFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    // The API only has a UUID — show its first 6 characters.
    func shortId(_ id: String) -> String {
        String(id.replacingOccurrences(of: "-", with: "").prefix(6)).uppercased()
    }

    func shipmentTitle(_ id: String) -> String {
        "Shipment #\(shortId(id))"
    }

    func requestTitle(_ id: String) -> String {
        "Request #\(shortId(id))"
    }

    func statusText(_ status: ShipmentStatus) -> String {
        switch status {
        case .preparingOptions: "Preparing options"
        case .optionsReady: "Options ready"
        case .approved: "Approved"
        case .inTransit: "In transit"
        case .unknown: "Unknown"
        }
    }

    func statusTone(_ status: ShipmentStatus) -> StatusTone {
        switch status {
        case .optionsReady: .success
        case .preparingOptions: .pending
        case .approved: .info
        case .inTransit, .unknown: .neutral
        }
    }

    func price(_ value: Double) -> String {
        value.formatted(.currency(code: "USD")
            .precision(.fractionLength(0))
            .locale(Locale(identifier: "en_US")))
    }

    func arrival(_ date: Date) -> String {
        arrivalFormatter.string(from: date)
    }

    // "Sea · Lowest price", "Air · Fastest", or just "Sea".
    func optionTitle(mode: ShippingMode, rank: OptionRank?) -> String {
        var parts = [mode.displayName]
        if rank?.isCheapest == true { parts.append("Lowest price") }
        if rank?.isFastest == true { parts.append("Fastest") }
        return parts.joined(separator: " · ")
    }

    // camelCase request key → label shown on the failure screen.
    func fieldLabel(_ field: String) -> String {
        switch field {
        case "quantity": "Quantity"
        case "weightKg": "Weight"
        case "dimensions": "Dimensions"
        case "packageType": "Package type"
        case "deliveryDate": "Delivery date"
        case "shippingMode": "Sea / Air"
        case "pickupAddress": "Pickup address"
        case "deliveryAddress": "Delivery address"
        case "priority": "Priority"
        case "temperatureControl": "Temp control"
        case "customsBy": "Customs by"
        case "insuranceBy": "Insurance by"
        case "localTruckingBy": "Trucking by"
        case "incoterms": "Incoterms"
        default: field
        }
    }
}
