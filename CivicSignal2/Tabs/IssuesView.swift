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
    
    private var tabs: [IssueFilter] = [.submitted, .acknowledged, .pending, .resolved]
    
    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with title
                HStack {
                    Text("My Issues")
                        .font(AppFont.largeTitle.bold())
                        .foregroundColor(.almostBlack)
                    
                    Spacer()
                    
                    // Tab button component
//                    TabButton(
//                        title: "Notifications",
//                        count: 0,
//                        isSelected: false,
//                        action: {}
//                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Tab selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(tabs) { tab in
                            TabButton(
                                title: tab.rawValue,
                                count: viewModel.count(for: tab),
                                isSelected: selectedFilter == tab
                            ) {
                                withAnimation {
                                    selectedFilter = tab
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
                
                // Main content
                if viewModel.isLoading && currentIssues.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if currentIssues.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(currentIssues) { issue in
                                    NavigationLink(destination: IssueDetailView(issueId: issue._id)) {
                                        IssueRow(issue: issue)
                                            .padding(.horizontal, 20)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                if viewModel.hasMore {
                                    Button(action: { Task { await viewModel.loadMore() } }) {
                                        Text("Load More")
                                            .font(AppFont.body)
                                            .foregroundColor(.accentColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .padding(.bottom, 40) // leave space above bottom tab bar
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
    
    private struct TabButton: View {
        let title: String
        let count: Int
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 5) {
                    Text(title)
                        .font(AppFont.subheadline.bold())
                        .foregroundColor(isSelected ? .mainBackground : .almostBlack)
                        .padding(.horizontal, 16)
                    
                    Text("\(count)")
                        .font(AppFont.title3.bold())
                        .foregroundColor(isSelected ? .mainBackground : .almostBlack)
                }
                .frame(width: 130, height: 60)
                .background(isSelected ? Color.accentGreen : Color.lightGray)
                .cornerRadius(16)
                .shadow(color: isSelected ? Color.accentGreen.opacity(0.3) : .clear, radius: 5, x: 1, y: 2)
                .padding(.horizontal, 10)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No \(selectedFilter.rawValue.lowercased()) issues found")
                .font(AppFont.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
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
