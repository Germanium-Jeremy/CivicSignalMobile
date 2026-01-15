//
//  ResetView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 26/11/2025.
//

import SwiftUI
import Foundation

struct ResetView: View {
    let identifier: String
    @State private var code: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text("Reset your password")
                        .font(AppFont.title)
                        .foregroundColor(.almostBlack)
                    
                    // Fields
                    VStack(spacing: 16) {
                        secureField(placeholder: "Code", text: $code)
                            .padding(.horizontal, 16) // Add padding for smaller screens
                        
                        secureField(placeholder: "New Password", text: $newPassword)
                            .padding(.horizontal, 16) // Add padding for smaller screens
                        
                        secureField(placeholder: "Confirm Password", text: $confirmPassword)
                            .padding(.horizontal, 16) // Add padding for smaller screens
                    }
                    
                    // Button
                    Button(action: handleResetPassword) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Reset Password")
                                .font(AppFont.body.weight(.semibold))
                                .foregroundColor(.mainBackground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.primaryBlue)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 16) // Add padding for smaller screens
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 600, alignment: .center)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func handleResetPassword() {
        guard !code.isEmpty, !newPassword.isEmpty, newPassword == confirmPassword else { return }
        isLoading = true
        Task {
            do {
                let url = URL(string: "https://civic-signal.vercel.app/api/auth/reset-password")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "identifier": identifier,
                    "resetCode": code,
                    "newPassword": newPassword,
                    "method": identifier.contains("@") ? "email" : "phone"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode([String: String].self, from: data)
                print("Success: \(response)")
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }
    
    private func secureField(placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(AppFont.body)
            .foregroundColor(.almostBlack) // Explicitly set text color to black
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationView {
        ResetView(identifier: "example@example.com") // Provide a default identifier for preview
    }
}
