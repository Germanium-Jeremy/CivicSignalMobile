//
//  SettingsView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 27/11/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            profileHeader

                            statsRow

                            settingsList
                        }
                        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20) // Adjust padding for iPads
                        .padding(.bottom, 80)
                    }
                    .refreshable {
                        await viewModel.fetchData(forceRefresh: true)
                    }
                }
            }
        }
        .onAppear { Task { await viewModel.fetchData() } }
    }
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primaryBlue)
            }
            
            Spacer()
            
            Text("Profile")
                .font(AppFont.title3)
                .foregroundColor(.almostBlack)
            
            Spacer()
            
            Image(systemName: "square.and.pencil")
                .foregroundColor(.primaryBlue)
        }
        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20)
        .padding(.top, 12)
    }
    
    private var profileHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.neutralGray.opacity(0.2))
                    .frame(width: 90, height: 90)
                
                if let initials = initials(from: viewModel.userFullName), !initials.isEmpty {
                    Text(initials)
                        .font(AppFont.title.weight(.bold))
                        .foregroundColor(.almostBlack)
                } else {
                    Image("civicsignal")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                }
            }
            
            Text(viewModel.userFullName)
                .font(AppFont.title3)
                .foregroundColor(.almostBlack)
            Text(viewModel.userRole)
                .font(AppFont.footnote)
                .foregroundColor(.neutralGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
    }

    private func initials(from name: String) -> String? {
        let parts = name
            .split(separator: " ")
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
    
    private var statsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                statCard(value: "\(viewModel.stats.submitted)", label: "Submitted")
                statCard(value: "\(viewModel.stats.acknowledged)", label: "Acknowledged")
                statCard(value: "\(viewModel.stats.pending)", label: "Pending")
                statCard(value: "\(viewModel.stats.resolved)", label: "Resolved")
            }
            // Counteract parent horizontal padding so the stats span more of the width
            .padding(.horizontal, -0)
        }
        .frame(maxWidth: 700, alignment: .center)
        .padding(.vertical, 32)
    }
    
    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFont.body)
                .foregroundColor(.almostBlack)
                .padding(.horizontal, 16)
            Text(label)
                .font(AppFont.footnote)
                .foregroundColor(.neutralGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
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
        .frame(maxWidth: 800, alignment: .center)
    }
}

// MARK: - ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    struct UserStats {
        var total: Int
        var submitted: Int
        var acknowledged: Int
        var pending: Int
        var resolved: Int
        
        init(total: Int = 0, submitted: Int = 0, acknowledged: Int = 0, pending: Int = 0, resolved: Int = 0) {
            self.total = total
            self.submitted = submitted
            self.acknowledged = acknowledged
            self.pending = pending
            self.resolved = resolved
        }
    }
    
    @Published var userFullName: String = "User"
    @Published var userRole: String = "Citizen"
    @Published var stats = UserStats()
    @Published var isLoading = true
    
    func fetchData(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        
        // Fetch user data
        if let user: UserDTO = TokenManager.getUserData(UserDTO.self) {
            userFullName = user.fullName ?? "User"
            // UserDTO has no explicit role field; default to a generic role label
            userRole = "Citizen"
        }
        
        // Fetch stats with cache-busting
        let result = await IssueService.getMyStats(forceRefresh: forceRefresh)
        guard result.success, let response = result.data else {
            print("Failed to fetch stats: \(result.error ?? "Unknown error")")
            return
        }
        
        self.stats = UserStats(
            total: response.data.total,
            submitted: response.data.submitted,
            acknowledged: response.data.acknowledged,
            pending: response.data.inProgress,
            resolved: response.data.resolved
        )
    }
}

#Preview {
    SettingsView()
}
