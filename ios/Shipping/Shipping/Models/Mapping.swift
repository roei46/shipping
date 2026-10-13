//
//  Mapping.swift
//  Shipping
//
//  DTO ↔ domain.
//

import Foundation

// Dates on the wire are "YYYY-MM-DD", in the user's calendar day.
enum APIDate {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        formatter.date(from: string)
    }
}

extension Shipment {
    init(dto: ShipmentSummaryDTO) {
        self.init(id: dto.requestId, status: ShipmentStatus(rawValue: dto.status) ?? .unknown)
    }
}

extension ShippingOption {
    init(dto: OptionDTO) throws {
        guard let mode = ShippingMode(rawValue: dto.mode),
              let container = ContainerType(rawValue: dto.containerType),
              let arrival = APIDate.date(from: dto.estimatedArrival) else {
            throw NetworkError.decodeError
        }
        self.init(id: dto.optionId, mode: mode, price: dto.price,
                  estimatedArrival: arrival, containerType: container)
    }
}

extension ShipmentDetails {
    init(dto: ShipmentDetailsDTO) throws {
        self.init(id: dto.requestId,
                  status: ShipmentStatus(rawValue: dto.status) ?? .unknown,
                  options: try dto.options.map { try ShippingOption(dto: $0) })
    }
}

extension CreateShipmentBody {
    init(request: ShipmentRequest) {
        self.init(quantity: request.quantity,
                  weightKg: request.weightKg,
                  dimensions: DimensionsDTO(lengthCm: request.lengthCm,
                                            widthCm: request.widthCm,
                                            heightCm: request.heightCm),
                  packageType: request.packageType.rawValue,
                  deliveryDate: APIDate.string(from: request.deliveryDate),
                  shippingMode: request.shippingMode.rawValue,
                  pickupAddress: request.pickupAddress,
                  deliveryAddress: request.deliveryAddress,
                  priority: request.priority.rawValue,
                  temperatureControl: request.temperatureControl,
                  customsBy: request.customsBy.rawValue,
                  insuranceBy: request.insuranceBy.rawValue,
                  localTruckingBy: request.localTruckingBy.rawValue,
                  incoterms: request.incoterms.rawValue)
    }
}
