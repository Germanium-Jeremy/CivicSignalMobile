import SwiftUI

struct IssueRow: View {
    let issue: IssueDTO
    
    private var statusColor: Color {
        switch issue.status.lowercased() {
        case "submitted": return .blue
        case "acknowledged": return .orange
        case "in_progress": return .yellow
        case "resolved": return .green
        case "closed": return .gray
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
                    
                    Text("Submitted: \(formattedDate)")
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
        submittedAt: "2025-12-11T12:00:00.000Z"
    ))
    .padding()
    .background(Color.mainBackground)
}
