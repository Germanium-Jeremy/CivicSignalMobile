//
//  ForgotView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 26/11/2025.
//

import SwiftUI

struct ForgotView: View {
    @State private var contact: String = ""
    
    var body: some View {
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
                    Text("You will a code that allows you recover your account and reset the password to your account.")
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
                    Button(action: {}) {
                        Text("Get code")
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
}

#Preview {
    NavigationView {
        ForgotView()
    }
}
