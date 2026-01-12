//
//  ForgotView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 26/11/2025.
//

import SwiftUI
import Foundation

struct ForgotView: View {
    @State private var contact: String = ""
    @State private var isLoading: Bool = false
    @State private var navigateToReset: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.mainBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Enter your email or phone")
                            .font(AppFont.title)
                            .foregroundColor(.almostBlack)

                        // Description
                        Text("You will receive a code that allows you to recover your account and reset the password.")
                            .font(AppFont.body)
                            .foregroundColor(.neutralGray)
                            .fixedSize(horizontal: false, vertical: true)

                        // Field
                        TextField("Email or Phone", text: $contact)
                            .font(AppFont.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
                            )

                        // Button
                        Button(action: handleForgotPassword) {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Get code")
                                    .font(AppFont.body.weight(.semibold))
                                    .foregroundColor(.mainBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(Color.primaryBlue)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationDestination(isPresented: $navigateToReset) {
                ResetView(identifier: contact)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func handleForgotPassword() {
        guard !contact.isEmpty else { return }
        isLoading = true
        Task {
            do {
                let url = URL(string: "https://civic-signal.vercel.app/api/auth/forgot-password")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: Any] = ["identifier": contact, "method": contact.contains("@") ? "email" : "phone"]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode([String: String].self, from: data)
                print("Success: \(response)")
                navigateToReset = true
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationView {
        ForgotView()
    }
}
