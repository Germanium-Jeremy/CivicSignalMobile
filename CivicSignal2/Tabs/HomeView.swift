//
//  HomeView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 27/11/2025.
//

import SwiftUI

struct HomeView: View {
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
                            
                            statsCard
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Previous Issues")
                                    .font(AppFont.title3)
                                    .foregroundColor(.almostBlack)
                                
                                if viewModel.recentIssues.isEmpty {
                                    emptyIssuesCard
                                } else {
                                    ForEach(viewModel.recentIssues.prefix(3)) { issue in
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
    }
    
    private var header: some View {
        // ... keep existing header implementation ...
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resolved Issues")
                        .font(AppFont.footnote)
                        .foregroundColor(.mainBackground)
                    Text("\(viewModel.stats.resolved)")
                        .font(AppFont.body)
                        .foregroundColor(.mainBackground)
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

// MARK: - ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var recentIssues: [IssueDTO] = []
    @Published var stats = (total: 0, resolved: 0, inProgress: 0)
    @Published var isLoading = true
    
    func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Fetch user data
        if let user: UserDTO = TokenManager.getUserData(UserDTO.self) {
            userName = user.fullName.components(separatedBy: " ").last ?? ""
        }
        
        // Fetch stats and issues in parallel
        async let statsTask = fetchStats()
        async let issuesTask = fetchRecentIssues()
        
        _ = await (statsTask, issuesTask)
    }
    
    private func fetchStats() async {
        let result = await IssueService.getMyStats()
        if case .success(let stats) = result {
            self.stats = (stats.data.total, stats.data.resolved, stats.data.inProgress)
        }
    }
    
    private func fetchRecentIssues() async {
        let result = await IssueService.getMyIssues(limit: 5)
        if case .success(let response) = result {
            recentIssues = response.data.issues
        }
    }
}

// MARK: - Issue Row
struct IssueRow: View {
    let issue: IssueDTO
    
    private var statusColor: Color {
        switch issue.status {
        case "submitted": return .red
        case "acknowledged": return .blue
        case "in_progress": return .yellow
        case "resolved": return .green
        case "closed": return .gray
        default: return .black
        }
    }
    
    var body: some View {
        NavigationLink(destination: IssueDetailView(issueId: issue._id)) {
            HStack(spacing: 12) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.title)
                        .font(AppFont.body.bold())
                        .foregroundColor(.almostBlack)
                        .lineLimit(1)
                    
                    Text("Submitted: \(formattedDate(issue.submittedAt))")
                        .font(AppFont.footnote)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
