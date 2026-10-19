//
//  HomeViewModel.swift
//  Shipping
//
//  My Shipments feed. Creates the two sheet VMs (New Shipment, Options),
//  passing them services only — like Portfol's getAddViewModel().
//

import Foundation

struct ShipmentRowState: Identifiable, Equatable {
    let id: String
    let title: String
    let statusText: String
    let tone: StatusTone
    let isTappable: Bool   // only "Options ready" opens the Options sheet
}

@MainActor
@Observable
final class HomeViewModel {
    private(set) var rows: [ShipmentRowState] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // Non-nil = sheet is shown. A push deep link will set `options` too.
    var newShipment: NewShipmentViewModel?
    var options: OptionsViewModel?

    private let service: ShipmentServiceProtocol
    private let keychain: KeychainServiceProtocol
    private let formatter = ShipmentFormatter()

    init(service: ShipmentServiceProtocol, keychain: KeychainServiceProtocol) {
        self.service = service
        self.keychain = keychain
    }

    func load() async {
        isLoading = rows.isEmpty
        defer { isLoading = false }

        do {
            rows = try await service.fetchShipments().map(makeRow)
            errorMessage = nil
        } catch NetworkError.unauthorized {
            logout()
        } catch {
            errorMessage = "Couldn't load shipments. Pull to refresh."
        }
    }

    func select(_ row: ShipmentRowState) {
        guard row.isTappable else { return }
        openOptions(for: row.id)
    }

    func openOptions(for shipmentId: String) {
        options = OptionsViewModel(service: service, keychain: keychain, shipmentId: shipmentId)
    }

    func startNewShipment() {
        #if DEBUG
        let prefill = true    // filled-in form while testing
        #else
        let prefill = false
        #endif
        newShipment = NewShipmentViewModel(service: service, keychain: keychain, prefill: prefill)
    }

    func logout() {
        rows = []
        newShipment = nil
        options = nil
        keychain.deleteToken()
    }

    private func makeRow(_ shipment: Shipment) -> ShipmentRowState {
        ShipmentRowState(id: shipment.id,
                         title: formatter.shipmentTitle(shipment.id),
                         statusText: formatter.statusText(shipment.status),
                         tone: formatter.statusTone(shipment.status),
                         isTappable: shipment.status == .optionsReady)
    }
}
