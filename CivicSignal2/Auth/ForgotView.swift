//
//  ForgotView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 26/11/2025.
//

import SwiftUI
import Foundation

struct ForgotView: View {
    @EnvironmentObject var session: AppSession
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var navigateToResetView = false
    @State private var identifier: String = ""

    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(alignment: .leading, spacing: 24) {
                    Text("Forgot Password")
                        .font(AppFont.title)
                        .foregroundColor(.almostBlack)

                    authTextField(placeholder: "Email", text: $email)
                        .textInputAutocapitalization(.never)

                    Button(action: {
                        Task {
                            await handleForgotPassword()
                        }
                    }) {
                        Text(isLoading ? "Sending..." : "Send Reset Link")
                            .font(AppFont.body.weight(.semibold))
                            .foregroundColor(.mainBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(isLoading ? Color.primaryBlue.opacity(0.6) : Color.primaryBlue)
                            .cornerRadius(20)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 24)

                Spacer()
            }

            NavigationLink(
                destination: ResetView(identifier: identifier)
                    .environmentObject(session),
                isActive: $navigateToResetView
            ) { EmptyView() }
            .hidden()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func authTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AppFont.body)
            .foregroundColor(.almostBlack) // Explicitly set text color to black
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
            )
    }

    private func handleForgotPassword() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Please enter your email."
            showAlert = true
            return
        }

        isLoading = true
        let result = await AuthService.forgotPassword(email: trimmedEmail.lowercased())
        isLoading = false

        if result.success, let id = result.data?.identifier {
            identifier = id
            navigateToResetView = true
        } else {
            alertTitle = "Request Failed"
            alertMessage = result.error ?? "An unknown error occurred."
            showAlert = true
        }
    }
}

#Preview {
    NavigationView {
        ForgotView()
    }
}
