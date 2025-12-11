//
//  WaitingView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 26/11/2025.
//

import SwiftUI

struct WaitingView: View {
    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 16) {
                        HStack {
                            Spacer()
                            Image("favicon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                            Spacer()
                        }
                        
                        Text("Account not verified")
                            .font(AppFont.title)
                            .foregroundColor(.almostBlack)
                    }
                    
                    Text("Two verification codes have been sent to your contacts. One to your email and another to your phone number.")
                        .font(AppFont.body)
                        .foregroundColor(.almostBlack)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(action: {}) {
                        Text("Continue")
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
                
                VStack(spacing: 0) {
                    Text("Didn’t receive the codes? ")
                        .font(AppFont.footnote)
                        .foregroundColor(.neutralGray)
                    Text("Resent code via email or phone number.")
                        .font(AppFont.footnote.weight(.semibold))
                        .foregroundColor(.almostBlack)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationView {
        WaitingView()
    }
}
