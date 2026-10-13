//
//  FormFields.swift
//  Shipping
//
//  Text field and dropdown in the PDF style. Once filled, the placeholder
//  moves up as a small caption so "Buyer" still says what it's for.
//

import SwiftUI

struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: KeyboardKind = .text
    var isInvalid = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if !text.isEmpty {
                FieldCaption(text: placeholder)
            }
            TextField(placeholder, text: $text)
                .keyboard(keyboard)
                .foregroundStyle(.ink)
        }
        .fieldChrome(isInvalid: isInvalid)
    }
}

struct MenuField<Value: Hashable & CaseIterable & DisplayNamed>: View where Value.AllCases: RandomAccessCollection {
    let placeholder: String
    @Binding var selection: Value?
    var isInvalid = false

    var body: some View {
        Menu {
            Picker(placeholder, selection: $selection) {
                ForEach(Value.allCases, id: \.self) { value in
                    Text(value.displayName).tag(Optional(value))
                }
            }
        } label: {
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 1) {
                    if let selection {
                        FieldCaption(text: placeholder)
                        Text(selection.displayName)
                            .foregroundStyle(.ink)
                    } else {
                        Text(placeholder)
                            .foregroundStyle(.inkSecondary)
                    }
                }
                .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.inkSecondary)
            }
            .fieldChrome(isInvalid: isInvalid)
            .contentShape(Rectangle())
        }
        .tint(.ink)
    }
}

struct FieldCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.inkSecondary)
    }
}
