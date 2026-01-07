import SwiftUI

struct IssueRow: View {
    let issue: IssueDTO
    
    private var statusColor: Color {
        switch issue.status.lowercased() {
        case "submitted": return .blue
        case "acknowledged": return .orange
        case "pending": return .yellow
        case "resolved": return .green
        default: return .black
        }
    }
    
    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: issue.submittedAt) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
        }
        return issue.submittedAt
    }
    
    private var categoryName: String {
        issue.category.capitalized
    }
    
    private var descriptionPreview: String {
        if let desc = issue.description, !desc.isEmpty {
            return String(desc.prefix(15)) + (desc.count > 15 ? "..." : "")
        }
        return "No description"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image("civic-signal-logo") // Make sure to add this image to your assets
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(categoryName), \(descriptionPreview)")
                    .font(AppFont.body.bold())
                    .foregroundColor(.almostBlack)
                    .lineLimit(1)
                
                Text("Submitted: \(formattedDate)")
                    .font(AppFont.footnote)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    IssueRow(issue: IssueDTO(
        _id: "1",
        trackingNumber: "TRK123",
        title: "Test Issue",
        description: "Test description",
        category: "Other",
        priority: "Medium",
        status: "submitted",
        location: nil,
        photos: nil,
        submittedAt: "2025-12-11T12:00:00.000Z",
        createdAt: "2025-12-11T12:00:00.000Z",
        updatedAt: "2025-12-11T12:00:00.000Z",
        isPublic: true,
        showOnMap: true,
        viewCount: 0,
        upvoteCount: 0,
        resolutionNotes: "",
        activities: [],
        reportedBy: ReportedByDTO.init(id:"", fullName: "", email: "")
    ))
    .padding()
    .background(Color.mainBackground)
}
