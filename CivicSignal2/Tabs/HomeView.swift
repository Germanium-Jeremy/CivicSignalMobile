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
                            
                            // Stats Card
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
                            
                            // Recent Issues
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Previous Issues")
                                    .font(AppFont.title3)
                                    .foregroundColor(.almostBlack)
                                
                                if viewModel.recentIssues.isEmpty {
                                    // Empty State
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
        HStack {
            Circle()
                .fill(Color.lightGray)
                .frame(width: 40, height: 40)
            
            Spacer()
            
            Text("Home")
                .font(AppFont.title3)
                .foregroundColor(.almostBlack)
            
            Spacer()
            
            NavigationLink(destination: NotificationsView()) {
                ZStack {
                    Circle()
                        .stroke(Color.secondaryGreen.opacity(0.3), lineWidth: 2)
                        .background(Circle().fill(Color.mainBackground))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "bell")
                        .foregroundColor(.primaryBlue)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
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
        guard result.success, let response = result.data else {
            print("Failed to fetch recent issues: \(result.error ?? "Unknown error")")
            return
        }
        recentIssues = response.data.issues
    }
}

// MARK: - Issue Row
struct IssueRow: View {
    let issue: IssueDTO
    
    private var statusColor: Color {
        switch issue.status {
        case "submitted": return .red
        case "acknowledged": return .blue
        case "pending": return .yellow
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
