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
                            TextEditor(placeholder: "Enter the description of the issue you are reporting.", text: $draft.description)
                                .font(AppFont.body)
                                .foregroundColor(.almostBlack) // Set text color to black
                                .padding(.horizontal, 16) // Add padding for smaller screens
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.mainBackground) // Set background color to white
                                        .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
                                )
                        }

                        // Location section (optional)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("📍 Location (Optional)")
                                    .font(AppFont.body.weight(.medium))
                                Spacer()
                                
                                if draft.latitude != nil && draft.longitude != nil {
                                    Button("Remove") {
                                        draft.latitude = nil
                                        draft.longitude = nil
                                        draft.address = nil
                                        draft.district = nil
                                        draft.sector = nil
                                    }
                                    .font(AppFont.footnote)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                } else {
                                    Button("Add Location") { Task { await fetchLocation() } }
                                        .font(AppFont.footnote)
                                        .foregroundColor(.primaryBlue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.primaryBlue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            
                            if let lat = draft.latitude, let lon = draft.longitude {
                                VStack(alignment: .leading, spacing: 6) {
                                    if let addr = draft.address {
                                        Text(addr)
                                            .font(AppFont.footnote)
                                            .foregroundColor(.almostBlack)
                                    }
                                    
                                    if draft.district != nil || draft.sector != nil {
                                        Text("\(draft.district ?? "") \(draft.sector ?? "")")
                                            .font(AppFont.footnote)
                                            .foregroundColor(.neutralGray)
                                    }
                                    
                                    Text("Lat: \(String(format: "%.6f", lat)), Lon: \(String(format: "%.6f", lon))")
                                        .font(AppFont.footnote)
                                        .foregroundColor(.neutralGray)
                                        .padding(.top, 4)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.lightGray.opacity(0.3))
                                .cornerRadius(12)
                            } else {
                                Text("No location added. Your report will be processed without location data.")
                                    .font(AppFont.footnote)
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
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
                                .background(Color.primaryBlue)
                                .cornerRadius(20)
                        }
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20) // Adjust padding for iPads
                    .padding(.bottom, 80)
                }
            }
            // Hidden navigation link
            NavigationLink(destination: ReportEvidenceView(draft: draft, issueId: createdIssueId ?? ""), isActive: $navigateToEvidence) { EmptyView() }
                .hidden()
        }
        .onAppear { Task { await loadCategories(); await fetchLocation() } }
        .alert(alertTitle, isPresented: $showAlert) { Button("OK", role: .cancel) {} } message: { Text(alertMessage) }
        .sheet(isPresented: $showCategorySheet) { categorySheet }
        .sheet(isPresented: $showPrioritySheet) { prioritySheet }
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

    private func fetchLocation() async {
        do {
            let c = try await locationService.getCurrentLocation()
            draft.latitude = c.latitude
            draft.longitude = c.longitude
            if let rev = try? await locationService.reverseGeocode(lat: c.latitude, lon: c.longitude) {
                draft.address = rev.address
                draft.district = rev.district
                draft.sector = rev.sector
            }
        } catch {
            alertTitle = "Location Error"
            alertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showAlert = true
        }
    }

    // MARK: - Continue
    private func handleContinue() async {
        guard !draft.category.isEmpty else { 
            show("Please select a category")
            return 
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
                Button(cat.name) { draft.category = cat.id; showCategorySheet = false }
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
