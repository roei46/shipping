//
//  SubmitResultViews.swift
//  Shipping
//
//  What replaces the form after Submit: success (201) or failure (422 / local).
//

import SwiftUI

struct SubmitSuccessView: View {
    let state: SubmitSuccessState
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ResultIcon(systemName: "checkmark", color: .success)
            Text("Request received")
                .font(.title.bold())
                .foregroundStyle(.ink)
            Text(state.requestTitle)
                .foregroundStyle(.inkSecondary)
            StatusBadge(text: state.statusText, tone: .success, fullWidth: true)
            Text("We'll notify you when your options are ready.")
                .foregroundStyle(.inkSecondary)
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(.primary)
        }
        .padding(24)
    }
}

struct SubmitFailureView: View {
    let errors: [FieldErrorState]
    let onFix: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ResultIcon(systemName: "exclamationmark", color: .danger)
            Text("Couldn't send request")
                .font(.title.bold())
                .foregroundStyle(.ink)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(errors) { error in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(error.label)
                                .font(.subheadline.weight(.semibold))
                            Text(error.message)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.dangerText)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.dangerTint, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            Button("Fix", action: onFix)
                .buttonStyle(.dark)
        }
        .padding(24)
    }
}

private struct ResultIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 60, height: 60)
            .background(color, in: Circle())
    }
}

#Preview("Success") {
    SubmitSuccessView(state: SubmitSuccessState(requestTitle: "Request #3F9A2C",
                                                statusText: "Preparing options")) {}
        .background(Color.appBackground)
}

#Preview("Failure") {
    SubmitFailureView(errors: [
        FieldErrorState(id: "deliveryDate", label: "Delivery date", message: "Must be a future date"),
        FieldErrorState(id: "weightKg", label: "Weight", message: "Required")
    ]) {}
        .background(Color.appBackground)
}
