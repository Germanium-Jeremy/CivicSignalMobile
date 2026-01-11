//
//  VerifyCodeView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 26/11/2025.
//

import SwiftUI

struct VerifyEmailView: View {
    @EnvironmentObject var session: AppSession
    let email: String
    let phone: String
    
    @State private var code: String = ""
    @State private var isLoading: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var navigateToPhoneVerify: Bool = false
    @State private var registeredPhone: String = ""
    
    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Centered content
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 16) {
                        HStack {
                            Spacer()
                            Image("civicsignal")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                            Spacer()
                        }
                        
                        Text("Verify your email")
                            .font(AppFont.title)
                            .foregroundColor(.almostBlack)
                    }
                    
                    TextField("Enter the code from your email", text: $code)
                        .font(AppFont.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
                        )
                    
                    Button(action: {
                        Task { await handleVerifyEmail() }
                    }) {
                        Text(isLoading ? "Verifying..." : "Continue")
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
                
                Button(action: {
                    Task { await handleResendEmail() }
                }) {
                    Text("Didn’t receive the code?")
                        .font(AppFont.footnote)
                        .foregroundColor(.neutralGray)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
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
        .navigationDestination(isPresented: $navigateToPhoneVerify) {
            VerifyPhoneView(phone: phone)
                .environmentObject(session)
        }
    }
    
    private func handleVerifyEmail() async {
        guard code.count == 6 else {
            alertTitle = "Error"
            alertMessage = "Enter 6-digit code."
            showAlert = true
            return
        }
        
        isLoading = true
        let result = await AuthService.verifyEmail(email: email, code: code)
        isLoading = false
        
        if result.success {
            if result.data?.fullyVerified == true {
                session.isLoggedIn = true
            } else {
                navigateToPhoneVerify = true
            }
        } else {
            alertTitle = "Verification Failed"
            alertMessage = result.error ?? "Verification failed."
            showAlert = true
            code = ""
        }
    }
    
    private func handleResendEmail() async {
        let result = await AuthService.resendEmailCode(email: email)
        if result.success {
            alertTitle = "Success"
            alertMessage = "New code sent to email."
        } else {
            alertTitle = "Error"
            alertMessage = result.error ?? "Failed to resend code."
        }
        showAlert = true
    }
}

#Preview {
    NavigationView {
        VerifyEmailView(email: "test@example.com", phone: "+250700000000")
            .environmentObject(AppSession())
    }
}
