//
//  Theme.swift
//  Shipping
//
//  Colors and shared styles taken from the system-design PDF.
//

import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// Usable as `.foregroundStyle(.ink)` and `Color.ink`.
extension ShapeStyle where Self == Color {
    static var appBackground: Color { Color(hex: 0xFAF8F3) }
    static var cardBackground: Color { Color(hex: 0xFFFFFF) }
    static var cardBorder: Color { Color(hex: 0xE5DFD3) }

    static var ink: Color { Color(hex: 0x1E2433) }
    static var inkSecondary: Color { Color(hex: 0x6B6F76) }

    static var gold: Color { Color(hex: 0xE0A526) }
    static var goldText: Color { Color(hex: 0x9A6B00) }

    static var success: Color { Color(hex: 0x2E7D4F) }
    static var successTint: Color { Color(hex: 0xE3EFE7) }
    static var pendingTint: Color { Color(hex: 0xF6E7C1) }
    static var info: Color { Color(hex: 0x2F5D8A) }
    static var infoTint: Color { Color(hex: 0xDFE8F2) }
    static var neutral: Color { Color(hex: 0x4B5058) }
    static var neutralTint: Color { Color(hex: 0xE6E6E3) }

    static var danger: Color { Color(hex: 0xB5441E) }
    static var dangerText: Color { Color(hex: 0x8F2F12) }
    static var dangerTint: Color { Color(hex: 0xF6E1DA) }
}

// MARK: - Buttons

struct ThemeButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        ThemeButton(configuration: configuration, background: background, foreground: foreground)
    }

    private struct ThemeButton: View {
        let configuration: ButtonStyleConfiguration
        let background: Color
        let foreground: Color
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(background, in: RoundedRectangle(cornerRadius: 12))
                .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
        }
    }
}

extension ButtonStyle where Self == ThemeButtonStyle {
    static var primary: ThemeButtonStyle { ThemeButtonStyle(background: .gold, foreground: .ink) }
    static var dark: ThemeButtonStyle { ThemeButtonStyle(background: .ink, foreground: .white) }
}

// MARK: - Card

struct CardModifier: ViewModifier {
    var isSelected = false

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.gold : Color.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
    }
}

// MARK: - Input field chrome

struct FieldChromeModifier: ViewModifier {
    var isInvalid = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isInvalid ? Color.danger : Color.cardBorder, lineWidth: isInvalid ? 1.5 : 1)
            )
    }
}

extension View {
    func card(isSelected: Bool = false) -> some View {
        modifier(CardModifier(isSelected: isSelected))
    }

    func fieldChrome(isInvalid: Bool = false) -> some View {
        modifier(FieldChromeModifier(isInvalid: isInvalid))
    }
}

// MARK: - iOS-only input helpers (keep macOS builds clean)

enum KeyboardKind {
    case text, integer, decimal
}

extension View {
    @ViewBuilder
    func keyboard(_ kind: KeyboardKind) -> some View {
        #if os(iOS)
        switch kind {
        case .text: self
        case .integer: self.keyboardType(.numberPad)
        case .decimal: self.keyboardType(.decimalPad)
        }
        #else
        self
        #endif
    }

    @ViewBuilder
    func noAutocapitalization() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never).autocorrectionDisabled()
        #else
        self.autocorrectionDisabled()
        #endif
    }
}
