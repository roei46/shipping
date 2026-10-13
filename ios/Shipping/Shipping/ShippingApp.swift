//
//  ShippingApp.swift
//  Shipping
//
//  Created by roei baruch on 13/10/2026.
//

import SwiftUI

@main
struct ShippingApp: App {
    // No server yet — flip to false once EndPoint has a base URL.
    private static let useMockServer = true

    // Composition root: build dependencies once, hold them, inject down.
    private let keychain: KeychainService
    @State private var loginViewModel: LoginViewModel
    @State private var homeViewModel: HomeViewModel

    init() {
        // One instance: LoginViewModel saves the token, HomeViewModel deletes it,
        // NetworkLayer reads it, RootView watches it.
        let keychain = KeychainService()
        let network = NetworkLayer(keychain: keychain)
        let hello = HelloService(network: network)   // always the real server
        let auth: AuthServiceProtocol
        let shipmentService: ShipmentServiceProtocol

        if Self.useMockServer {
            auth = MockAuthService()
            shipmentService = MockShipmentService()
        } else {
            auth = AuthService(network: network)
            shipmentService = ShipmentService(network: network)
        }

        self.keychain = keychain
        _loginViewModel = State(initialValue: LoginViewModel(auth: auth, keychain: keychain, hello: hello))
        _homeViewModel = State(initialValue: HomeViewModel(service: shipmentService, keychain: keychain))
    }

    var body: some Scene {
        WindowGroup {
            RootView(keychain: keychain, loginViewModel: loginViewModel, homeViewModel: homeViewModel)
        }
    }
}
