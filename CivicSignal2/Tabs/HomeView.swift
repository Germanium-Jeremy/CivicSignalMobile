//
//  HomeView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 27/11/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: AppSession
    @StateObject private var viewModel = HomeViewModel()
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                if viewModel.isLoading && !isRefreshing {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Welcome \(viewModel.userName)")
                                .font(AppFont.title)
                                .foregroundColor(.almostBlack)
                                .padding(.top, 24)
                            
                            // Stats Card
                            statsCard
                            
                            // Recent Issues
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Previous Issues")
                                    .font(AppFont.body.weight(.semibold))
                                    .foregroundColor(.almostBlack)
                                
                                if viewModel.recentIssues.isEmpty {
                                    emptyIssuesCard
                                } else {
                                    ForEach(viewModel.recentIssues, id: \..id) { issue in
                                        IssueRow(issue: issue)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                    .refreshable { await viewModel.fetchData() }
                }
            }
        }
        .onAppear { Task { await viewModel.fetchData() } }
        .onChange(of: session.homeRefreshToken) { _ in
            Task { await viewModel.fetchData() }
        }
    }
    
    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.lightGray)
                        .frame(width: 40, height: 40)
                    Image("civic-signal-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                
                Spacer()
                
                Text("Home")
                    .font(AppFont.title3)
                    .foregroundColor(.almostBlack)
                
                Spacer()
                
                // Placeholder to keep header layout without notifications feature
                ZStack {
                    Circle()
                        .stroke(Color.secondaryGreen.opacity(0.0), lineWidth: 2)
                        .background(Circle().fill(Color.mainBackground))
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            Divider()
                .background(Color.lightGray)
        }
    }
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Submitted Issues")
                        .font(AppFont.footnote)
                        .foregroundColor(.mainBackground)
                    Text("\(viewModel.stats.total)")
                        .font(AppFont.title)
                        .foregroundColor(.mainBackground)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Resolved Issues")
                            .font(AppFont.footnote)
                            .foregroundColor(.mainBackground)
                        Text("\(viewModel.stats.resolved)")
                            .font(AppFont.body)
                            .foregroundColor(.mainBackground)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pending Issues")
                            .font(AppFont.footnote)
                            .foregroundColor(.mainBackground)
                        Text("\(viewModel.stats.inProgress)")
                            .font(AppFont.body)
                            .foregroundColor(.mainBackground)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.almostBlack)
        .cornerRadius(16)
    }
    
    private var emptyIssuesCard: some View {
        VStack(spacing: 16) {
            Text("You haven't submitted any issue yet.")
                .font(AppFont.body)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            
            NavigationLink(destination: ReportView()) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.lightGray)
        .cornerRadius(16)
    }
}

// Duplicate IssueRow removed. Shared IssueRow component is used. ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    struct Stats {
        var total: Int
        var resolved: Int
        var inProgress: Int
        
        init(total: Int = 0, resolved: Int = 0, inProgress: Int = 0) {
            self.total = total
            self.resolved = resolved
            self.inProgress = inProgress
        }
    }
    
    @Published var userName: String = ""
    @Published var recentIssues: [IssueDTO] = []
    @Published var stats = Stats()
    @Published var isLoading = true
    
    func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Fetch user data
        if let user: UserDTO = TokenManager.getUserData(UserDTO.self) {
            userName = user.fullName?.components(separatedBy: " ").last ?? ""
        }
        
        // Fetch stats and issues in parallel
        async let statsTask: () = fetchStats()
        async let issuesTask: () = fetchRecentIssues()
        
        _ = await (statsTask, issuesTask)
    }
    
    private func fetchStats() async {
        let result = await IssueService.getMyStats()
        print("Recent Issues: \(result)")
        guard result.success, let response = result.data else {
            print("Failed to fetch stats: \(result.error ?? "Unknown error")")
            return
        }
        self.stats = Stats(
            total: response.data.total,
            resolved: response.data.resolved,
            inProgress: response.data.inProgress
        )
    }
    
    private func fetchRecentIssues() async {
        let result = await IssueService.getMyIssues(limit: 5)
        print("Recent Issues: \(result)")
        guard result.success, let response = result.data else {
            print("Failed to fetch recent issues: \(result.error ?? "Unknown error")")
            return
        }
        recentIssues = response.data.issues
    }
}
