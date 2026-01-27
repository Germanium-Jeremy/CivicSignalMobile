import SwiftUI

struct IssueDetailView: View {
    let issueId: String
    @StateObject private var viewModel = IssueDetailViewModel()
    
    private func absoluteMediaURL(_ pathOrURL: String) -> URL? {
        // If backend already returns absolute URL, use it
        if let url = URL(string: pathOrURL), url.scheme != nil {
            return url
        }
        // Otherwise, build from API baseURL by removing "/api" then appending path
        let apiBase = APIConfig.baseURL
        let hostBase = apiBase.lastPathComponent == "api" ? apiBase.deletingLastPathComponent() : apiBase
        let trimmed = pathOrURL.hasPrefix("/") ? String(pathOrURL.dropFirst()) : pathOrURL
        return hostBase.appendingPathComponent(trimmed)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let issue = viewModel.issue {
                    // Header (centered, closer to Figma)
                    VStack(alignment: .center, spacing: 8) {
                        Text(issue.title.isEmpty ? issue.category : issue.title)
                            .font(AppFont.title)
                            .foregroundColor(.almostBlack)
                            .multilineTextAlignment(.center)

                        if let description = issue.description, !description.isEmpty {
                            Text(description)
                                .font(AppFont.body)
                                .foregroundColor(.almostBlack)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }

                        // Status pill
                        HStack {
                            Spacer()
                            statusPill(issue.status)
                            Spacer()
                        }
                        .padding(.top, 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // Category & Priority (kept, but below header)
                    HStack(spacing: 16) {
                        infoBox(title: "Category", value: issue.category)
                        infoBox(title: "Priority", value: issue.priority.capitalized)
                    }
                    .padding(.bottom, 16)

                    // Photos (optional)
                    if let photos = issue.photos, !photos.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photos")
                                .font(AppFont.headline)
                                .foregroundColor(.almostBlack)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photos, id: \.url) { photo in
                                        // Using AsyncImage to load images asynchronously
                                        if let url = absoluteMediaURL(photo.url) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .cornerRadius(8)
                                            } placeholder: {
                                                ProgressView()
                                                    .frame(width: 120, height: 120)
                                                    .background(Color.lightGray)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    
                    // Comments / Activities card
                    if let activities = issue.activities, !activities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Comments Given By Authorities")
                                .font(AppFont.headline)
                                .foregroundColor(.mainBackground)
                                .padding(.top, 12)
                            
                            Divider()
                                .background(Color.mainBackground)
                            
                            ForEach(Array(activities.enumerated()), id: \.offset) { _, activity in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.mainBackground)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.almostBlack)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Government Agency")
                                            .font(AppFont.body)
                                            .foregroundColor(.almostBlack)
                                        
                                        Text(formattedActivityDate(activity.timestamp))
                                            .font(AppFont.footnote)
                                            .foregroundColor(.almostBlack)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.lightGray.opacity(0.7))
                                .cornerRadius(16)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.almostBlack)
                        .cornerRadius(24)
                        .padding(.top, 8)
                    }
                    
                } else if let error = viewModel.error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
        .navigationBarTitle("Issue Details", displayMode: .inline)
        .onAppear {
            Task {
                await viewModel.fetchIssue(id: issueId)
            }
        }
        .background(.white)
        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 80 : 20)
    }
    
    private func statusBadge(_ status: String) -> some View {
        let (text, color) = statusInfo(for: status)
        return Text(text)
            .font(AppFont.footnote.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }

    // Larger, pill-style status view to match Figma more closely
    private func statusPill(_ status: String) -> some View {
        let (text, color) = statusInfo(for: status)
        return HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(text.capitalized)
                .font(AppFont.body)
                .foregroundColor(.almostBlack)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.lightGray.opacity(0.6))
        .cornerRadius(20)
    }
    
    private func statusInfo(for status: String) -> (String, Color) {
        switch status.lowercased() {
        case "submitted": return ("SUBMITTED", .blue)
        case "acknowledged": return ("ACKNOWLEDGED", .orange)
        case "pending": return ("IN PROGRESS", .yellow)
        case "resolved": return ("RESOLVED", .green)
        case "closed": return ("CLOSED", .gray)
        default: return (status.uppercased(), .black)
        }
    }
    
    private func infoBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(AppFont.caption2)
                .foregroundColor(.gray)
            
            Text(value)
                .font(AppFont.body)
                .foregroundColor(.almostBlack)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lightGray.opacity(0.3))
        .cornerRadius(8)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
        }
        return dateString
    }

    private func formattedActivityDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
        }
        return dateString
    }
}

@MainActor
class IssueDetailViewModel: ObservableObject {
    @Published var issue: IssueDTO?
    @Published var isLoading = false
    @Published var error: String?
    
    func fetchIssue(id: String) async {
        isLoading = true
        defer { isLoading = false }
        
        let result = await IssueService.getIssue(id: id)
        
        if result.success, let fetched = result.data {
            self.issue = fetched
            self.error = nil
        } else {
            let message = result.error ?? "Failed to fetch issue"
            self.error = message
            print("Failed to fetch issue: \(message)")
        }
    }
}

#Preview {
    NavigationView {
        IssueDetailView(issueId: "1")
    }
}
