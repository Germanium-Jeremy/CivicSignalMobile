//
//  IssuesView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 27/11/2025.
//

import SwiftUI

enum IssueFilter: String, CaseIterable, Identifiable {
    case submitted = "Submitted"
    case acknowledged = "Acknowledged"
    case pending = "Pending"
    case resolved = "Resolved"
    
    var id: String { self.rawValue }
    
    var statusValue: String {
        switch self {
        case .submitted: return "submitted"
        case .acknowledged: return "acknowledged"
        case .pending: return "pending"
        case .resolved: return "resolved"
        }
    }
}

struct IssuesView: View {
    @StateObject private var viewModel = IssuesViewModel()
    @State private var selectedFilter: IssueFilter = .submitted
    
    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            filterRow
                            
                            Text("\(selectedFilter.rawValue) Issues")
                                .font(AppFont.title3)
                                .foregroundColor(.almostBlack)
                                .padding(.top, 8)
                            
                            if currentIssues.isEmpty {
                                emptyStateView
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(currentIssues) { issue in
                                        IssueRow(issue: issue)
                                    }
                                }
                                
                                if viewModel.hasMore {
                                    Button(action: { Task { await viewModel.loadMore() } }) {
                                        Text("Load more")
                                            .font(AppFont.body)
                                            .foregroundColor(.accentColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                    .refreshable { await viewModel.refresh() }
                }
            }
        }
        .onAppear { Task { await viewModel.refresh() } }
        .onChange(of: selectedFilter) { _ in
            Task { await viewModel.loadIssues(for: selectedFilter) }
        }
    }
    
    private var currentIssues: [IssueDTO] {
        switch selectedFilter {
        case .submitted: return viewModel.submitted
        case .acknowledged: return viewModel.acknowledged
        case .pending: return viewModel.pending
        case .resolved: return viewModel.resolved
        }
    }
    
    private var header: some View {
        HStack {
            Circle()
                .fill(Color.lightGray)
                .frame(width: 40, height: 40)
            
            Spacer()
            
            Text("Issues")
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
    
    private var filterRow: some View {
        HStack(spacing: 12) {
            ForEach(IssueFilter.allCases) { filter in
                VStack(spacing: 8) {
                    Text(filter.rawValue)
                        .font(AppFont.footnote)
                        .foregroundColor(selectedFilter == filter ? .white : .mainBackground)
                    Text("\(viewModel.count(for: filter))")
                        .font(AppFont.body)
                        .foregroundColor(selectedFilter == filter ? .white : .mainBackground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedFilter == filter ? Color.accentColor : Color.almostBlack)
                .cornerRadius(16)
                .onTapGesture { selectedFilter = filter }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No \(selectedFilter.rawValue.lowercased()) issues found")
                .font(AppFont.body)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - ViewModel
@MainActor
class IssuesViewModel: ObservableObject {
    @Published var submitted: [IssueDTO] = []
    @Published var acknowledged: [IssueDTO] = []
    @Published var pending: [IssueDTO] = []
    @Published var resolved: [IssueDTO] = []
    @Published var isLoading = false
    @Published var hasMore = true
    
    private var currentPage = 1
    private let pageSize = 10
    
    func count(for filter: IssueFilter) -> Int {
        switch filter {
        case .submitted: return submitted.count
        case .acknowledged: return acknowledged.count
        case .pending: return pending.count
        case .resolved: return resolved.count
        }
    }
    
    func refresh() async {
        currentPage = 1
        await loadAllIssues()
    }
    
    func loadMore() async {
        currentPage += 1
        await loadAllIssues(loadMore: true)
    }
    
    func loadIssues(for filter: IssueFilter) async {
        let status = filter.statusValue
        let result = await IssueService.getMyIssues(status: status, page: currentPage, limit: pageSize)
        
        guard result.success, let response = result.data else {
            print("Failed to load issues: \(result.error ?? "Unknown error")")
            return
        }
        let newIssues = response.data.issues
        updateIssues(newIssues, for: filter)
        hasMore = newIssues.count >= pageSize
    }
    
    private func loadAllIssues(loadMore: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        
        if !loadMore {
            submitted = []
            acknowledged = []
            pending = []
            resolved = []
        }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadIssues(for: .submitted) }
            group.addTask { await self.loadIssues(for: .acknowledged) }
            group.addTask { await self.loadIssues(for: .pending) }
            group.addTask { await self.loadIssues(for: .resolved) }
        }
    }
    
    private func updateIssues(_ newIssues: [IssueDTO], for filter: IssueFilter) {
        switch filter {
        case .submitted:
            if currentPage == 1 {
                submitted = newIssues
            } else {
                submitted.append(contentsOf: newIssues)
            }
        case .acknowledged:
            if currentPage == 1 {
                acknowledged = newIssues
            } else {
                acknowledged.append(contentsOf: newIssues)
            }
        case .pending:
            if currentPage == 1 {
                pending = newIssues
            } else {
                pending.append(contentsOf: newIssues)
            }
        case .resolved:
            if currentPage == 1 {
                resolved = newIssues
            } else {
                resolved.append(contentsOf: newIssues)
            }
        }
    }
}
