import SwiftUI

/// Reusable profile avatar component that displays user profile image, initials, or default icon
struct ProfileAvatar: View {
    let size: CGFloat
    let profileImageURL: String?
    let userName: String?
    let localImage: UIImage?

    init(size: CGFloat = 40, profileImageURL: String? = nil, userName: String? = nil, localImage: UIImage? = nil) {
        self.size = size
        self.profileImageURL = profileImageURL
        self.userName = userName
        self.localImage = localImage
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.lightGray)
                .frame(width: size, height: size)

            if let localImage = localImage {
                Image(uiImage: localImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let urlString = profileImageURL, let url = absoluteMediaURL(urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                fallbackView
            }
        }
    }

    private var fallbackView: some View {
        Group {
            if let initials = initials(from: userName ?? ""), !initials.isEmpty {
                Text(initials)
                    .font(AppFont.title.weight(.bold))
                    .foregroundColor(.almostBlack)
            } else {
                Image("civicsignal")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.7, height: size * 0.7)
            }
        }
    }

    private func initials(from name: String) -> String? {
        let parts = name
            .split(separator: " ")
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    // Helper to convert relative media paths to absolute URLs
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
}

#Preview {
    VStack(spacing: 20) {
        ProfileAvatar(size: 40, profileImageURL: nil, userName: "John Doe")
        ProfileAvatar(size: 60, profileImageURL: nil, userName: "Jane Smith")
        ProfileAvatar(size: 90, profileImageURL: nil, userName: nil)
    }
    .padding()
}
