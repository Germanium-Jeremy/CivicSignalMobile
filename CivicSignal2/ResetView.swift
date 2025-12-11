//
//  ResetView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 26/11/2025.
//

import SwiftUI

struct ResetView: View {
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
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
                        secureField(placeholder: "New Password", text: $newPassword)
                        secureField(placeholder: "Confirm Password", text: $confirmPassword)
                    }
                    
                    // Button
                    Button(action: {}) {
                        Text("Reset Password")
                            .font(AppFont.body.weight(.semibold))
                            .foregroundColor(.mainBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.primaryBlue)
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func secureField(placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(AppFont.body)
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
        ResetView()
    }
}
