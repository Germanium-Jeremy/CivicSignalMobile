import SwiftUI

private enum MainTab: Int {
    case home = 0
    case issues
    case report
    case map
    case profile
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        HomeView()
                    }
                case .issues:
                    NavigationStack {
                        IssuesView()
                    }
                case .report:
                    NavigationStack {
                        ReportView()
                    }
                case .map:
                    NavigationStack {
                        MapView()
                    }
                case .profile:
                    NavigationStack {
                        SettingsView()
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // Custom bottom bar
            bottomBar
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(Color.mainBackground)
    }

    private var bottomBar: some View {
        HStack(spacing: 36) {
            tabButton(
                icon: "house.fill",
                tab: .home
            )

            tabButton(
                icon: "exclamationmark.bubble.fill",
                tab: .issues
            )

            // Center plus – larger
            ZStack {
                Circle()
                    .fill(Color.mainBackground)
                    .frame(width: 56, height: 56)

                Circle()
                    .fill(Color.primaryBlue)
                    .frame(width: 44, height: 44)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.mainBackground)
            }
            .onTapGesture {
                selectedTab = .report
            }

            tabButton(
                icon: "map.fill",
                tab: .map
            )

            tabButton(
                icon: "person.fill",
                tab: .profile
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.almostBlack)
        )
    }

    private func tabButton(icon: String, tab: MainTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(
                    selectedTab == tab ? .primaryBlue : .lightGray // Updated color for selected tab
                )
                .frame(width: 28, height: 28)
        }
    }
}

#Preview {
    MainTabView()
}
