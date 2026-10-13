//
//  OptionsView.swift
//  Shipping
//
//  Sheet: choose one option → Approve. Opened from the feed or (later) a push.
//

import SwiftUI

struct OptionsView: View {
    let viewModel: OptionsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SheetHeader(title: viewModel.title, subtitle: "Choose an option") { dismiss() }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.cards) { card in
                            Button {
                                viewModel.select(card.id)
                            } label: {
                                OptionCard(card: card, isSelected: card.id == viewModel.selectedOptionId)
                            }
                            .buttonStyle(.plain)
                        }
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(viewModel.cards.isEmpty ? .inkSecondary : .danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await viewModel.approve() }
            } label: {
                if viewModel.isApproving {
                    ProgressView().tint(.ink)
                } else {
                    Text("Approve")
                }
            }
            .buttonStyle(.primary)
            .disabled(!viewModel.canApprove)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .interactiveDismissDisabled(viewModel.isApproving)
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.isApproved) { _, isApproved in
            if isApproved { dismiss() }
        }
    }
}

// MARK: - One option card (presentation only)

private struct OptionCard: View {
    let card: OptionCardState
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.title)
                .font(.headline)
                .foregroundStyle(.ink)
            detailRow("Price", card.price)
            detailRow("Est. arrival", card.arrival)
            detailRow("Container", card.container)
            if isSelected {
                Label("Selected", systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.goldText)
            }
        }
        .card(isSelected: isSelected)
        .contentShape(Rectangle())
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.inkSecondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.ink)
        }
        .font(.subheadline)
    }
}

#Preview {
    OptionsView(viewModel: OptionsViewModel(service: MockShipmentService(),
                                            keychain: InMemoryKeychainService(),
                                            shipmentId: MockShipmentService.readyShipmentId))
}
