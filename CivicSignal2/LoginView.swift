//
//  LoginView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 26/11/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: AppSession
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var navigateToVerifyEmail = false
    @State private var navigateToVerifyPhone = false
    @State private var pendingEmail = ""
    @State private var pendingPhone = ""
    
    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Centered content block
                VStack(alignment: .leading, spacing: 24) {
                    // Favicon + title
                    VStack(spacing: 16) {
                        HStack {
                            Spacer()
                            Image("favicon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                            Spacer()
                        }
                        
                        Text("Log into your account")
                            .font(AppFont.title)
                            .foregroundColor(.almostBlack)
                    }
                    
                    // Fields
                    VStack(spacing: 16) {
                        authTextField(placeholder: "Email", text: $email)
                        secureAuthField(placeholder: "Password", text: $password)
                    }
                    
                    // Forgot password
                    HStack {
                        Spacer()
                        Button(action: {}) {
                            Text("Forgot password?")
                                .font(AppFont.subheadline)
                                .foregroundColor(.neutralGray)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Main button
                    Button(action: {
                        Task {
                            await handleLogin()
                        }
                    }) {
                        Text(isLoading ? "Signing in..." : "Login")
                            .font(AppFont.body.weight(.semibold))
                            .foregroundColor(.mainBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(isLoading ? Color.primaryBlue.opacity(0.6) : Color.primaryBlue)
                            .cornerRadius(20)
                    }
                    .disabled(isLoading)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Bottom prompt
                HStack(spacing: 4) {
                    Text("Don’t have an account?")
                        .font(AppFont.footnote)
                        .foregroundColor(.neutralGray)
                    
                    Button(action: {}) {
                        Text("Signup")
                            .font(AppFont.footnote.weight(.semibold))
                            .foregroundColor(.almostBlack)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
                if isLoading {
                    ProgressView()
                        .tint(.primaryBlue)
                        .padding(.bottom, 16)
                }
            }

            NavigationLink(
                destination: VerifyEmailView(email: pendingEmail, phone: pendingPhone)
                    .environmentObject(session),
                isActive: $navigateToVerifyEmail
            ) { EmptyView() }
            .hidden()

            NavigationLink(
                destination: VerifyPhoneView(phone: pendingPhone)
                    .environmentObject(session),
                isActive: $navigateToVerifyPhone
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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
            )
    }

    private func secureAuthField(placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(AppFont.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
            )
    }
    
    private func handleLogin() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Please enter both email and password."
            showAlert = true
            return
        }
        
        isLoading = true
        let result = await AuthService.login(email: trimmedEmail.lowercased(), password: trimmedPassword)
        isLoading = false
        
        if result.success {
            let name = result.data?.user?.fullName ?? ""
            alertTitle = "Welcome!"
            alertMessage = name.isEmpty ? "Login successful." : "Hello \(name)!"
            showAlert = true
            // Navigate to main app
            session.isLoggedIn = true
        } else if result.requiresVerification, let info = result.verificationInfo {
            let message = info.message ?? "Complete account verification to continue."
            alertTitle = "Verification Required"
            alertMessage = message
            showAlert = true

            let emailToUse = info.email ?? trimmedEmail.lowercased()
            let phoneToUse = info.phone ?? ""

            pendingEmail = emailToUse
            pendingPhone = phoneToUse

            if !info.emailVerified {
                navigateToVerifyEmail = true
            } else if !info.phoneVerified {
                navigateToVerifyPhone = true
            }
        } else {
            alertTitle = "Login Failed"
            alertMessage = result.error ?? "An unknown error occurred."
            showAlert = true
        }
    }
}

#Preview {
    NavigationView {
        LoginView()
    }
}
