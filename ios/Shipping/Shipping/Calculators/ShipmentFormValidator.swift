//
//  ShipmentFormValidator.swift
//  Shipping
//
//  Raw form input → a valid ShipmentRequest, or field errors.
//  Same rules as the server, so most 422s are caught before Submit.
//

import Foundation

// What the user typed / picked. Pickers start empty (nil) like the design.
struct ShipmentForm: Equatable {
    var quantity = ""
    var weightKg = ""
    var lengthCm = ""
    var widthCm = ""
    var heightCm = ""
    var packageType: PackageType?
    var deliveryDate: Date
    var shippingMode: ShippingMode?
    var pickupAddress = ""
    var deliveryAddress = ""
    var priority: Priority?
    var temperatureControl = false
    var customsBy: Party?
    var insuranceBy: Party?
    var localTruckingBy: Party?
    var incoterms: Incoterms?
}

enum FormValidation: Equatable {
    case valid(ShipmentRequest)
    case invalid([FieldError])
}

struct ShipmentFormValidator {
    func validate(_ form: ShipmentForm, today: Date, calendar: Calendar = .current) -> FormValidation {
        var errors: [FieldError] = []

        let quantity = Int(trimmed(form.quantity))
        if (quantity ?? 0) <= 0 {
            errors.append(FieldError(field: "quantity", message: positiveMessage(form.quantity)))
        }

        let weight = Double(trimmed(form.weightKg))
        if (weight ?? 0) <= 0 {
            errors.append(FieldError(field: "weightKg", message: positiveMessage(form.weightKg)))
        }

        let length = Double(trimmed(form.lengthCm))
        let width = Double(trimmed(form.widthCm))
        let height = Double(trimmed(form.heightCm))
        if [length, width, height].contains(where: { ($0 ?? 0) <= 0 }) {
            errors.append(FieldError(field: "dimensions", message: "Length, width and height must be greater than 0"))
        }

        if calendar.startOfDay(for: form.deliveryDate) <= calendar.startOfDay(for: today) {
            errors.append(FieldError(field: "deliveryDate", message: "Must be a future date"))
        }

        if trimmed(form.pickupAddress).isEmpty {
            errors.append(FieldError(field: "pickupAddress", message: "Required"))
        }
        if trimmed(form.deliveryAddress).isEmpty {
            errors.append(FieldError(field: "deliveryAddress", message: "Required"))
        }

        let pickers: [(String, Bool)] = [
            ("packageType", form.packageType == nil),
            ("shippingMode", form.shippingMode == nil),
            ("priority", form.priority == nil),
            ("customsBy", form.customsBy == nil),
            ("insuranceBy", form.insuranceBy == nil),
            ("localTruckingBy", form.localTruckingBy == nil),
            ("incoterms", form.incoterms == nil)
        ]
        for (field, isMissing) in pickers where isMissing {
            errors.append(FieldError(field: field, message: "Required"))
        }

        guard errors.isEmpty,
              let quantity, let weight, let length, let width, let height,
              let packageType = form.packageType,
              let shippingMode = form.shippingMode,
              let priority = form.priority,
              let customsBy = form.customsBy,
              let insuranceBy = form.insuranceBy,
              let localTruckingBy = form.localTruckingBy,
              let incoterms = form.incoterms else {
            return .invalid(errors)
        }

        return .valid(ShipmentRequest(quantity: quantity,
                                      weightKg: weight,
                                      lengthCm: length,
                                      widthCm: width,
                                      heightCm: height,
                                      packageType: packageType,
                                      deliveryDate: form.deliveryDate,
                                      shippingMode: shippingMode,
                                      pickupAddress: trimmed(form.pickupAddress),
                                      deliveryAddress: trimmed(form.deliveryAddress),
                                      priority: priority,
                                      temperatureControl: form.temperatureControl,
                                      customsBy: customsBy,
                                      insuranceBy: insuranceBy,
                                      localTruckingBy: localTruckingBy,
                                      incoterms: incoterms))
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func positiveMessage(_ text: String) -> String {
        trimmed(text).isEmpty ? "Required" : "Must be greater than 0"
    }
}
