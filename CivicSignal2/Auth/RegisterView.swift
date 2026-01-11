//
//  RegisterView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 26/11/2025.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var session: AppSession
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var navigateToVerifyEmail: Bool = false
    @State private var registeredEmail: String = ""
    @State private var registeredPhone: String = ""
    
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
                            Image("civicsignal")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                            Spacer()
                        }
                        
                        Text("Create an account")
                            .font(AppFont.title)
                            .foregroundColor(.almostBlack)
                    }
                    
                    // Fields
                    VStack(spacing: 16) {
                        authTextField(placeholder: "Full Names", text: $fullName)
                        authTextField(placeholder: "Email", text: $email).textInputAutocapitalization(.never)
                        authTextField(placeholder: "Phone Number", text: $phone)
                        secureAuthField(placeholder: "Password", text: $password)
                    }
                    
                    // Main button
                    Button(action: {
                        Task {
                            await handleSignup()
                        }
                    }) {
                        Text(isLoading ? "Signing up..." : "Register")
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
                    Text("Already have an account?")
                        .font(AppFont.footnote)
                        .foregroundColor(.neutralGray)
                    
                    Button(action: {}) {
                        Text("Login")
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
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .navigationDestination(isPresented: $navigateToVerifyEmail) {
            VerifyEmailView(email: registeredEmail, phone: registeredPhone)
                .environmentObject(session)
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
    
    private func handleSignup() async {
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedPhone = phone.replacingOccurrences(of: " ", with: "")
        let pwd = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty, !normalizedEmail.isEmpty, !normalizedPhone.isEmpty, !pwd.isEmpty else {
            alertTitle = "Error"
            alertMessage = "All fields are required."
            showAlert = true
            return
        }
        
        guard pwd.count >= 8 else {
            alertTitle = "Error"
            alertMessage = "Password must be at least 8 characters."
            showAlert = true
            return
        }
        
        isLoading = true
        let result = await AuthService.register(
            fullName: name,
            email: normalizedEmail,
            phone: normalizedPhone,
            password: pwd
        )
        isLoading = false
        
        if result.success {
            registeredEmail = normalizedEmail
            registeredPhone = normalizedPhone
            navigateToVerifyEmail = true
        } else {
            var message = result.error ?? "Registration failed."
            if let details = result.details, !details.isEmpty {
                message += "\n\n" + details
            }
            alertTitle = "Registration Failed"
            alertMessage = message
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AppSession())
    }
}
