//
//  StatusBadge.swift
//  Shipping
//

import SwiftUI

struct StatusBadge: View {
    let text: String
    let tone: StatusTone
    var fullWidth = false

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, fullWidth ? 10 : 5)
            .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
            .background(tintColor, in: RoundedRectangle(cornerRadius: fullWidth ? 10 : 6))
    }

    private var textColor: Color {
        switch tone {
        case .success: .success
        case .pending: .goldText
        case .info: .info
        case .neutral: .neutral
        }
    }

    private var tintColor: Color {
        switch tone {
        case .success: .successTint
        case .pending: .pendingTint
        case .info: .infoTint
        case .neutral: .neutralTint
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        StatusBadge(text: "Options ready", tone: .success)
        StatusBadge(text: "Preparing options", tone: .pending)
        StatusBadge(text: "Approved", tone: .info)
        StatusBadge(text: "In transit", tone: .neutral)
    }
    .padding()
}
