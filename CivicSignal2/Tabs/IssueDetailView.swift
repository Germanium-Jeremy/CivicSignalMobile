import SwiftUI

struct IssueDetailView: View {
    let issueId: String
    @StateObject private var viewModel = IssueDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let issue = viewModel.issue {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(issue.title)
                            .font(AppFont.largeTitle)
                            .foregroundColor(.almostBlack)
                        
                        HStack(spacing: 8) {
                            statusBadge(issue.status)
                            
                            Text("#\(issue.trackingNumber)")
                                .font(AppFont.subheadline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text(formattedDate(issue.submittedAt))
                                .font(AppFont.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    // Description
                    if let description = issue.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(AppFont.headline)
                                .foregroundColor(.almostBlack)
                            
                            Text(description)
                                .font(AppFont.body)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 16)
                    }
                    
                    // Category & Priority
                    HStack(spacing: 16) {
                        infoBox(title: "Category", value: issue.category)
                        infoBox(title: "Priority", value: issue.priority.capitalized)
                    }
                    .padding(.bottom, 16)
                    
                    // Photos
                    if let photos = issue.photos, !photos.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photos")
                                .font(AppFont.headline)
                                .foregroundColor(.almostBlack)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photos, id: \.url) { photo in
                                        // Using AsyncImage to load images asynchronously
                                        if let url = URL(string: photo.url) {
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
                    
                    // Location
                    if let location = issue.location {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(AppFont.headline)
                                .foregroundColor(.almostBlack)
                            
                            if let address = location.address {
                                Text(address)
                                    .font(AppFont.body)
                                    .foregroundColor(.gray)
                            }
                            
                            // You can add a map view here using MapKit
                            // For now, we'll just show the coordinates
                            Text("\(location.latitude), \(location.longitude)")
                                .font(AppFont.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 16)
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
        
        if result.success, let response = result.data {
            self.issue = response.data.issue
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
