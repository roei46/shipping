//
//  NewShipmentView.swift
//  Shipping
//
//  Sheet: 14-field form → Submit result (success / failure) in place.
//

import SwiftUI

struct NewShipmentView: View {
    @Bindable var viewModel: NewShipmentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.phase {
            case .editing, .submitting:
                form
            case .success(let state):
                SubmitSuccessView(state: state) { dismiss() }
            case .failure(let errors):
                SubmitFailureView(errors: errors) { viewModel.fix() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground.ignoresSafeArea())
        .interactiveDismissDisabled(viewModel.isSubmitting)
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SheetHeader(title: "New Shipment") { dismiss() }

                Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        ThemedTextField(placeholder: "Quantity", text: $viewModel.form.quantity,
                                        keyboard: .integer, isInvalid: viewModel.isInvalid("quantity"))
                        ThemedTextField(placeholder: "Weight (kg)", text: $viewModel.form.weightKg,
                                        keyboard: .decimal, isInvalid: viewModel.isInvalid("weightKg"))
                    }
                    GridRow {
                        dimensions.gridCellColumns(2)
                    }
                    GridRow {
                        MenuField(placeholder: "Package type", selection: $viewModel.form.packageType,
                                  isInvalid: viewModel.isInvalid("packageType"))
                        MenuField(placeholder: "Sea / Air", selection: $viewModel.form.shippingMode,
                                  isInvalid: viewModel.isInvalid("shippingMode"))
                    }
                    GridRow {
                        deliveryDate.gridCellColumns(2)
                    }
                    GridRow {
                        ThemedTextField(placeholder: "Pickup address", text: $viewModel.form.pickupAddress,
                                        isInvalid: viewModel.isInvalid("pickupAddress"))
                            .gridCellColumns(2)
                    }
                    GridRow {
                        ThemedTextField(placeholder: "Delivery address", text: $viewModel.form.deliveryAddress,
                                        isInvalid: viewModel.isInvalid("deliveryAddress"))
                            .gridCellColumns(2)
                    }
                    GridRow {
                        MenuField(placeholder: "Priority", selection: $viewModel.form.priority,
                                  isInvalid: viewModel.isInvalid("priority"))
                        Toggle("Temp control", isOn: $viewModel.form.temperatureControl)
                            .foregroundStyle(.ink)
                            .tint(.gold)
                            .fieldChrome()
                    }
                    GridRow {
                        MenuField(placeholder: "Customs by", selection: $viewModel.form.customsBy,
                                  isInvalid: viewModel.isInvalid("customsBy"))
                        MenuField(placeholder: "Insurance by", selection: $viewModel.form.insuranceBy,
                                  isInvalid: viewModel.isInvalid("insuranceBy"))
                    }
                    GridRow {
                        MenuField(placeholder: "Trucking by", selection: $viewModel.form.localTruckingBy,
                                  isInvalid: viewModel.isInvalid("localTruckingBy"))
                        MenuField(placeholder: "Incoterms", selection: $viewModel.form.incoterms,
                                  isInvalid: viewModel.isInvalid("incoterms"))
                    }
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await viewModel.submit() }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView().tint(.ink)
                } else {
                    Text("Submit")
                }
            }
            .buttonStyle(.primary)
            .disabled(viewModel.isSubmitting)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(Color.appBackground)
        }
    }

    private var dimensions: some View {
        let isInvalid = viewModel.isInvalid("dimensions")
        return VStack(alignment: .leading, spacing: 4) {
            FieldCaption(text: "Dimensions (cm)")
            HStack(spacing: 8) {
                ThemedTextField(placeholder: "Length", text: $viewModel.form.lengthCm,
                                keyboard: .decimal, isInvalid: isInvalid)
                ThemedTextField(placeholder: "Width", text: $viewModel.form.widthCm,
                                keyboard: .decimal, isInvalid: isInvalid)
                ThemedTextField(placeholder: "Height", text: $viewModel.form.heightCm,
                                keyboard: .decimal, isInvalid: isInvalid)
            }
        }
    }

    private var deliveryDate: some View {
        HStack {
            Text("Delivery date")
                .foregroundStyle(.inkSecondary)
            Spacer()
            DatePicker("Delivery date",
                       selection: $viewModel.form.deliveryDate,
                       in: viewModel.earliestDeliveryDate...,
                       displayedComponents: .date)
                .labelsHidden()
                .tint(.goldText)
        }
        .fieldChrome(isInvalid: viewModel.isInvalid("deliveryDate"))
    }
}

// MARK: - Sheet header (title + close)

struct SheetHeader: View {
    let title: String
    var subtitle: String?
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.inkSecondary)
                }
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.inkSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.neutralTint, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}

#Preview {
    NewShipmentView(viewModel: NewShipmentViewModel(service: MockShipmentService(), keychain: InMemoryKeychainService()))
}
