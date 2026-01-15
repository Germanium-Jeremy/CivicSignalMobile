import SwiftUI

struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let body: String
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var items: [NotificationItem] = [
        NotificationItem(
            title: "Government Agency",
            date: "October 23rd, 2025 6:53 PM",
            body: "This is the description of a certain issue that was submitted by a certain user who is supposed to be seeing it only because he is the one who reported it. There can be long text given here..."
        ),
        NotificationItem(
            title: "Government Agency",
            date: "October 23rd, 2025 6:53 PM",
            body: "Another sample notification text."
        )
    ]

    @State private var selectedItem: NotificationItem? = nil

    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            notificationRow(item: item)
                                .onTapGesture {
                                    selectedItem = item
                                }
                        }
                    }
                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20)
                    .padding(.vertical, 16)
                    .navigationBarBackButtonHidden(true)
                }
            }

            if let item = selectedItem {
                overlayDetail(for: item)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primaryBlue)
            }

            Spacer()

            Text("Notifications")
                .font(AppFont.title3)
                .foregroundColor(.almostBlack)

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.secondaryGreen.opacity(0.3), lineWidth: 2)
                    .background(Circle().fill(Color.mainBackground))
                    .frame(width: 36, height: 36)

                Image(systemName: "bell")
                    .foregroundColor(.primaryBlue)
            }
        }
        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20)
        .padding(.top, 12)
    }

    private func notificationRow(item: NotificationItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.neutralGray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.neutralGray)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(AppFont.body)
                    .foregroundColor(.almostBlack)
                Text(item.date)
                    .font(AppFont.footnote)
                    .foregroundColor(.neutralGray)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.lightGray)
        .cornerRadius(20)
    }

    private func overlayDetail(for item: NotificationItem) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    selectedItem = nil
                }

            VStack(spacing: 16) {
                Circle()
                    .fill(Color.neutralGray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.neutralGray)
                    )

                Text(item.title)
                    .font(AppFont.title3)
                    .foregroundColor(.almostBlack)

                Text(item.date)
                    .font(AppFont.footnote)
                    .foregroundColor(.neutralGray)

                Text(item.body)
                    .font(AppFont.body)
                    .foregroundColor(.almostBlack)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 8)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: { selectedItem = nil }) {
                    Text("Done")
                        .font(AppFont.body.weight(.semibold))
                        .foregroundColor(.mainBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.primaryBlue)
                        .cornerRadius(20)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color.mainBackground)
            .cornerRadius(24)
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    NavigationView {
        NotificationsView()
    }
}
