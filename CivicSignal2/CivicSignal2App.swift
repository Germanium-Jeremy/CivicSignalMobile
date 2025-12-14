// CivicSignalApp.swift
import SwiftUI

final class AppSession: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var homeRefreshToken = UUID()

    func triggerHomeRefresh() {
        homeRefreshToken = UUID()
    }
}

@main
struct CivicSignalApp: App {
    @StateObject private var session = AppSession()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var session: AppSession
    
    var body: some View {
        if session.isLoggedIn {
            MainTabView()
        } else {
            NavigationStack {
                SplashView()
            }
        }
    }
}
