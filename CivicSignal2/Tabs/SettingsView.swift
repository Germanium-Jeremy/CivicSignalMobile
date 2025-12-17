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
        .onAppear { Task { await viewModel.fetchData() } }
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
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(viewModel.stats.submitted)", label: "Submitted")
            statCard(value: "\(viewModel.stats.acknowledged)", label: "Acknowledged")
            statCard(value: "\(viewModel.stats.pending)", label: "Pending")
            statCard(value: "\(viewModel.stats.resolved)", label: "Resolved")
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
    
    func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Fetch user data
        if let user: UserDTO = TokenManager.getUserData(UserDTO.self) {
            userFullName = user.fullName ?? "User"
            // UserDTO has no explicit role field; default to a generic role label
            userRole = "Citizen"
        }
        
        // Fetch stats
        let result = await IssueService.getMyStats()
        guard result.success, let response = result.data else {
            print("Failed to fetch stats: \(result.error ?? "Unknown error")")
            return
        }
        
        self.stats = UserStats(
            total: response.data.total,
            submitted: response.data.submitted,
            // StatsResponse.DataField does not include an acknowledged field in Swift aggregation;
            // use 0 for now, or adjust later if backend adds this metric.
            acknowledged: 0,
            pending: response.data.inProgress,
            resolved: response.data.resolved
        )
    }
}

#Preview {
    SettingsView()
}
