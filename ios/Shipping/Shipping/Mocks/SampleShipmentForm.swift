//
//  SampleShipmentForm.swift
//  Shipping
//
//  A filled-in New Shipment form for Debug builds, so testing doesn't mean
//  picking all 14 fields every time.
//

import Foundation

extension ShipmentForm {
    static func sample(deliveryDate: Date) -> ShipmentForm {
        var form = ShipmentForm(deliveryDate: deliveryDate)
        form.quantity = "1200"
        form.weightKg = "9800"
        form.lengthCm = "120"
        form.widthCm = "80"
        form.heightCm = "150"
        form.packageType = .bottles
        form.shippingMode = .sea
        form.pickupAddress = "Av. Javier Barros Sierra 555, Mexico City, Mexico"
        form.deliveryAddress = "Torstraße 1, 10119 Berlin, Germany"
        form.priority = .lowestPrice
        form.temperatureControl = false
        form.customsBy = .buyer
        form.insuranceBy = .seller
        form.localTruckingBy = .buyer
        form.incoterms = .dap
        return form
    }
}
