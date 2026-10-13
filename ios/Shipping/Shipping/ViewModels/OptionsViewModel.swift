//
//  OptionsViewModel.swift
//  Shipping
//
//  The Options sheet: load options → pick one → Approve.
//

import Foundation

struct OptionCardState: Identifiable, Equatable {
    let id: String
    let title: String       // "Sea · Lowest price"
    let price: String
    let arrival: String
    let container: String
}

@MainActor
@Observable
final class OptionsViewModel: Identifiable {
    let title: String
    private(set) var cards: [OptionCardState] = []
    private(set) var isLoading = false
    private(set) var isApproving = false
    private(set) var isApproved = false
    private(set) var errorMessage: String?
    private(set) var selectedOptionId: String?

    private let shipmentId: String
    private let service: ShipmentServiceProtocol
    private let keychain: KeychainServiceProtocol
    private let rankCalculator = OptionRankCalculator()
    private let formatter = ShipmentFormatter()

    var canApprove: Bool {
        selectedOptionId != nil && !isApproving && !isApproved
    }

    init(service: ShipmentServiceProtocol, keychain: KeychainServiceProtocol, shipmentId: String) {
        self.service = service
        self.keychain = keychain
        self.shipmentId = shipmentId
        self.title = formatter.shipmentTitle(shipmentId)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let details = try await service.fetchShipment(id: shipmentId)
            let ranks = rankCalculator.calcRanks(for: details.options)
            cards = details.options.map { option in
                OptionCardState(id: option.id,
                                title: formatter.optionTitle(mode: option.mode, rank: ranks[option.id]),
                                price: formatter.price(option.price),
                                arrival: formatter.arrival(option.estimatedArrival),
                                container: option.containerType.displayName)
            }
            errorMessage = cards.isEmpty ? "Your options are still being prepared." : nil
        } catch NetworkError.unauthorized {
            keychain.deleteToken()   // root view → Login
        } catch NetworkError.notFound {
            errorMessage = "This shipment no longer exists."
        } catch {
            errorMessage = "Couldn't load options. Try again."
        }
    }

    func select(_ optionId: String) {
        guard !isApproved else { return }
        selectedOptionId = optionId
    }

    func approve() async {
        guard canApprove, let selectedOptionId else { return }
        isApproving = true
        errorMessage = nil
        defer { isApproving = false }

        do {
            _ = try await service.approve(id: shipmentId, optionId: selectedOptionId)
            isApproved = true
        } catch NetworkError.unauthorized {
            keychain.deleteToken()   // root view → Login
        } catch NetworkError.conflict {
            errorMessage = "This shipment was already approved."
        } catch NetworkError.notFound {
            errorMessage = "This shipment no longer exists."
        } catch {
            errorMessage = "Couldn't approve. Try again."
        }
    }
}
