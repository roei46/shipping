//
//  RootView.swift
//  Shipping
//
//  Login ↔ Home, driven by the saved token. Everything else is a sheet.
//

import SwiftUI

struct RootView: View {
    let keychain: KeychainServiceProtocol
    let loginViewModel: LoginViewModel
    let homeViewModel: HomeViewModel

    var body: some View {
        Group {
            if keychain.token != nil {
                HomeView(viewModel: homeViewModel)
            } else {
                LoginView(viewModel: loginViewModel)
            }
        }
        .animation(.default, value: keychain.token != nil)
        .preferredColorScheme(.light)   // the design is light-only
    }
}
