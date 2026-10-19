//
//  LoginView.swift
//  Shipping
//

import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: LoginViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Corona")
                .font(.largeTitle.bold())
                .foregroundStyle(.ink)
            Text("Shipping")
                .font(.title3)
                .foregroundStyle(.inkSecondary)
                .padding(.top, 4)

            VStack(spacing: 12) {
                TextField("Username", text: $viewModel.username)
                    .textContentType(.username)
                    .noAutocapitalization()
                    .fieldChrome()
                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .fieldChrome()
            }
            .foregroundStyle(.ink)
            .padding(.top, 48)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.danger)
                    .padding(.top, 10)
            }

            Spacer()

            Button {
                Task { await viewModel.login() }
            } label: {
                if viewModel.isLoading {
                    ProgressView().tint(.ink)
                } else {
                    Text("Log in")
                }
            }
            .buttonStyle(.primary)
            .disabled(!viewModel.canSubmit)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.appBackground.ignoresSafeArea())
        .onSubmit {
            Task { await viewModel.login() }
        }
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(auth: MockAuthService(),
                                        keychain: InMemoryKeychainService()))
}
