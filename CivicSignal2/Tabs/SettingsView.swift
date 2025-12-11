//
//  SettingsView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 27/11/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader
                        statsRow
                        settingsList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 80)
                }
            }
        }
    }
    
    private var header: some View {
        HStack {
            Spacer()
            
            Text("Profile")
                .font(AppFont.title3)
                .foregroundColor(.almostBlack)
            
            Spacer()
            
            Image(systemName: "square.and.pencil")
                .foregroundColor(.primaryBlue)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    private var profileHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.neutralGray.opacity(0.2))
                    .frame(width: 90, height: 90)
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.neutralGray)
            }
            
            Text("Mugisha David")
                .font(AppFont.title3)
                .foregroundColor(.almostBlack)
            Text("Citizen")
                .font(AppFont.footnote)
                .foregroundColor(.neutralGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
    }
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "20", label: "Submitted")
            statCard(value: "20", label: "Acknowledged")
            statCard(value: "20", label: "Pending")
        }
    }
    
    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFont.body)
                .foregroundColor(.almostBlack)
            Text(label)
                .font(AppFont.footnote)
                .foregroundColor(.neutralGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.lightGray)
        .cornerRadius(12)
    }
    
    private var settingsList: some View {
        VStack(spacing: 0) {
            settingsRow(title: "Check for updates")
            settingsRow(title: "Contact Us")
            settingsRow(title: "Terms and Conditions")
            settingsRow(title: "Privacy Policies")
            settingsRow(title: "Logout")
        }
        .background(Color.mainBackground)
    }
    
    private func settingsRow(title: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(AppFont.body)
                    .foregroundColor(.almostBlack)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.primaryBlue)
            }
            .padding(.vertical, 14)
            
            Rectangle()
                .fill(Color.lightGray)
                .frame(height: 1)
        }
    }
}

#Preview {
    SettingsView()
}
