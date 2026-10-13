//
//  HomeView.swift
//  Shipping
//
//  My Shipments feed + "+ New Shipment". Both flows open as sheets.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button("+ New Shipment") {
                viewModel.startNewShipment()
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .task {
            await viewModel.load()
        }
        .sheet(item: $viewModel.newShipment, onDismiss: reload) { newShipmentVM in
            NewShipmentView(viewModel: newShipmentVM)
        }
        .sheet(item: $viewModel.options, onDismiss: reload) { optionsVM in
            OptionsView(viewModel: optionsVM)
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("My Shipments")
                .font(.title.bold())
                .foregroundStyle(.ink)
            Spacer()
            Button("Log out") {
                viewModel.logout()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.goldText)
        }
        .padding(.top, 16)
    }

    // MARK: - Feed

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if viewModel.rows.isEmpty && viewModel.errorMessage == nil {
                        Text("No shipments yet. Tap + New Shipment to start one.")
                            .font(.subheadline)
                            .foregroundStyle(.inkSecondary)
                            .padding(.vertical, 24)
                    }
                    ForEach(viewModel.rows) { row in
                        Button {
                            viewModel.select(row)
                        } label: {
                            ShipmentRow(row: row)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await viewModel.load()
            }
        }
    }
}

// MARK: - A single shipment card (presentation only)

private struct ShipmentRow: View {
    let row: ShipmentRowState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(row.title)
                    .font(.headline)
                    .foregroundStyle(.ink)
                StatusBadge(text: row.statusText, tone: row.tone)
            }
            Spacer()
            if row.isTappable {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.inkSecondary)
            }
        }
        .card()
        .contentShape(Rectangle())
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(service: MockShipmentService(),
                                      keychain: InMemoryKeychainService(token: "preview")))
}
