//
//  NewShipmentViewModel.swift
//  Shipping
//
//  The New Shipment sheet: form → Submit → success or failure (Fix → form).
//

import Foundation

struct SubmitSuccessState: Equatable {
    let requestTitle: String
    let statusText: String
}

struct FieldErrorState: Identifiable, Equatable {
    let id: String        // the camelCase field key
    let label: String
    let message: String
}

enum NewShipmentPhase: Equatable {
    case editing
    case submitting
    case success(SubmitSuccessState)
    case failure([FieldErrorState])
}

@MainActor
@Observable
final class NewShipmentViewModel: Identifiable {
    var form: ShipmentForm
    private(set) var phase: NewShipmentPhase = .editing
    private(set) var invalidFields: Set<String> = []
    let earliestDeliveryDate: Date

    private let service: ShipmentServiceProtocol
    private let keychain: KeychainServiceProtocol
    private let validator = ShipmentFormValidator()
    private let formatter = ShipmentFormatter()

    var isSubmitting: Bool { phase == .submitting }

    init(service: ShipmentServiceProtocol, keychain: KeychainServiceProtocol, now: Date = .now, calendar: Calendar = .current) {
        self.service = service
        self.keychain = keychain
        let today = calendar.startOfDay(for: now)
        self.earliestDeliveryDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let defaultDelivery = calendar.date(byAdding: .day, value: 30, to: today) ?? today
        self.form = ShipmentForm(deliveryDate: defaultDelivery)
    }

    func isInvalid(_ field: String) -> Bool {
        invalidFields.contains(field)
    }

    func submit() async {
        guard !isSubmitting else { return }

        switch validator.validate(form, today: .now) {
        case .invalid(let errors):
            showFailure(errors)
        case .valid(let request):
            phase = .submitting
            do {
                let shipment = try await service.create(request)
                invalidFields = []
                phase = .success(SubmitSuccessState(requestTitle: formatter.requestTitle(shipment.id),
                                                    statusText: formatter.statusText(shipment.status)))
            } catch NetworkError.validation(let errors) {
                showFailure(errors)
            } catch NetworkError.unauthorized {
                keychain.deleteToken()   // root view → Login
            } catch {
                phase = .failure([FieldErrorState(id: "connection",
                                                  label: "Connection",
                                                  message: "Couldn't reach the server. Try again.")])
            }
        }
    }

    // "Fix" → back to the form, with the bad fields highlighted.
    func fix() {
        phase = .editing
    }

    private func showFailure(_ errors: [FieldError]) {
        invalidFields = Set(errors.map(\.field))
        phase = .failure(errors.map {
            FieldErrorState(id: $0.field, label: formatter.fieldLabel($0.field), message: $0.message)
        })
    }
}
