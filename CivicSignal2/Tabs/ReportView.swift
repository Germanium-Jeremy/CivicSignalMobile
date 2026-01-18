//
//  ReportView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 27/11/2025.
//

import SwiftUI

struct CategoryItem: Identifiable {
    let id: String
    let name: String
}

struct ReportView: View {
    @EnvironmentObject var session: AppSession
    @StateObject private var draft = ReportDraft()
    @StateObject private var locationService = LocationService.shared
    @State private var categories: [CategoryItem] = []
    @State private var showCategorySheet: Bool = false
    @State private var showPrioritySheet: Bool = false
    @State private var navigateToEvidence: Bool = false
    @State private var createdIssueId: String? = nil
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @ObservedObject var locationManager = LocationManager.shared
    
    init() {
        UITextView.appearance().backgroundColor = .clear
    }

    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Fill the form to report the issue")
                            .font(AppFont.title)
                            .foregroundColor(.almostBlack)
                            .padding(.top, 24)

                        Button(action: { showCategorySheet = true }) {
                            dropdownRow(title: "Select Issue Category", value: draft.category)
                        }
                        Button(action: { showPrioritySheet = true }) {
                            dropdownRow(title: "Select Issue Priority", value: draft.priority.capitalized)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter the description of the issue you are reporting.")
                                .font(AppFont.body)
                                .foregroundColor(.almostBlack)
                            TextEditor(text: $draft.description)
                                .font(AppFont.body)
                                .foregroundColor(.almostBlack)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .scrollContentBackground(.hidden)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.white)
                                        .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
                                )
                        }

                        // Location section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Your Location")
                                    .font(AppFont.body.weight(.medium))
                                Spacer()

                                if let location = locationManager.userLocation {
                                    Text("\(location.coordinate.latitude), \(location.coordinate.longitude)")
                                        .font(AppFont.footnote)
                                        .foregroundColor(.neutralGray)
                                } else {
                                    Text("Fetching location...")
                                        .font(AppFont.footnote)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.accentGreen.opacity(0.3), lineWidth: 1)
                        )

                        Button(action: { Task { await handleContinue() } }) {
                            Text("Continue")
                                .font(AppFont.body.weight(.semibold))
                                .foregroundColor(.mainBackground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.almostBlack)
                                .cornerRadius(20)
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20)
                    .padding(.bottom, 80)
                }
            }
        }
        .onAppear {
            locationManager.requestLocation()
            loadCategories() // Ensure categories are loaded on appear
        }
        .alert(alertTitle, isPresented: $showAlert) { Button("OK", role: .cancel) {} } message: { Text(alertMessage) }
        .sheet(isPresented: Binding(get: { showCategorySheet || showPrioritySheet }, set: { newValue in
            if !newValue {
                showCategorySheet = false
                showPrioritySheet = false
            }
        })) {
            if showCategorySheet {
                categorySheet
            } else if showPrioritySheet {
                prioritySheet
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.lightGray)
                    .frame(width: 40, height: 40)
                Image("civicsignal")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }

            Spacer()

            Text("Report")
                .font(AppFont.title3)
                .foregroundColor(.almostBlack)

            Spacer()

            // Placeholder to keep header layout without notifications feature
            ZStack {
                Circle()
                    .stroke(Color.secondaryGreen.opacity(0.0), lineWidth: 2)
                    .background(Circle().fill(Color.mainBackground))
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20)
        .padding(.top, 12)
    }

    private func dropdownRow(title: String, value: String) -> some View {
        HStack {
            Text(value.isEmpty ? title : value)
                .font(AppFont.body)
                .foregroundColor(value.isEmpty ? .neutralGray : .almostBlack)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.primaryBlue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Data loading
    private func loadCategories() {
        categories = [
            CategoryItem(id: "1", name: "Infrastructure"),
            CategoryItem(id: "2", name: "Permits & Licensing"),
            CategoryItem(id: "3", name: "Utilities"),
            CategoryItem(id: "4", name: "Waste Management"),
            CategoryItem(id: "5", name: "Transportation"),
            CategoryItem(id: "6", name: "Emergency Services"),
            CategoryItem(id: "7", name: "Parks & Recreation"),
            CategoryItem(id: "8", name: "Other Services")
        ]
    }

    // MARK: - Continue
    private func handleContinue() async {
        guard !draft.category.isEmpty else {
            show("Please select a category")
            return
        }

        // Add location to the draft if available
        if let location = locationManager.userLocation {
            draft.latitude = location.coordinate.latitude
            draft.longitude = location.coordinate.longitude
        }

        // Show confirmation dialog if no location is provided
        if draft.latitude == nil || draft.longitude == nil {
            let shouldContinue = await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "No Location Provided",
                        message: "You're about to submit this report without location data. Would you like to continue?",
                        preferredStyle: .alert
                    )

                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        continuation.resume(returning: false)
                    })

                    alert.addAction(UIAlertAction(title: "Submit Anyway", style: .default) { _ in
                        continuation.resume(returning: true)
                    })

                    // Present the alert
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(alert, animated: true)
                    } else {
                        // Fallback if we can't present the alert
                        continuation.resume(returning: true)
                    }
                }
            }

            if !shouldContinue {
                return
            }
        }

        // Build optional location
        var loc: IssueLocationDTO? = nil
        if let lat = draft.latitude, let lon = draft.longitude {
            loc = IssueLocationDTO(latitude: lat, longitude: lon, address: draft.address, district: draft.district, sector: draft.sector)
        }

        let res = await IssueService.createIssue(
            title: nil,
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category,
            priority: draft.priority,
            location: loc,
            photos: nil
        )

        if res.success, let id = res.data?.data.issue._id {
            session.triggerHomeRefresh()
            createdIssueId = id
            navigateToEvidence = true
        } else {
            show(res.error ?? "Failed to create issue. Please try again.")
        }
    }
    private func show(_ message: String) { alertTitle = "Error"; alertMessage = message; showAlert = true }

    // MARK: - Sheets
    private var categorySheet: some View {
        NavigationView {
            List(categories) { cat in
                Button(cat.name) { draft.category = cat.name; showCategorySheet = false }
            }
            .navigationTitle("Categories")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { showCategorySheet = false } } }
        }
    }

    private var prioritySheet: some View {
        NavigationView {
            List {
                ForEach(["low","medium","high","urgent"], id: \.self) { p in
                    Button(p.capitalized) { draft.priority = p; showPrioritySheet = false }
                }
            }
            .navigationTitle("Priority")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { showPrioritySheet = false } } }
        }
    }
}

#Preview {
    ReportView()
}
