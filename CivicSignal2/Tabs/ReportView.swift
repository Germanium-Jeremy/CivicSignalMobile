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
                            Text("Enter the description of the issue you are reporting.")
                                .font(AppFont.body)
                                .foregroundColor(.almostBlack)
                            
                            TextEditor(text: $draft.description)
                                .font(AppFont.body)
                                .frame(minHeight: 120, alignment: .topLeading)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
                                )
                        }

                        // Location summary
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("📍 Location")
                                    .font(AppFont.body.weight(.semibold))
                                Spacer()
                                Button("Update") { Task { await fetchLocation() } }
                                    .font(AppFont.footnote)
                                    .foregroundColor(.primaryBlue)
                            }
                            if let addr = draft.address { Text(addr).font(AppFont.footnote) }
                            if draft.district != nil || draft.sector != nil {
                                Text("\(draft.district ?? "") \(draft.sector ?? "")")
                                    .font(AppFont.footnote)
                                    .foregroundColor(.neutralGray)
                            }
                            if let lat = draft.latitude, let lon = draft.longitude {
                                Text("lat: \(lat), lon: \(lon)").font(AppFont.footnote).foregroundColor(.neutralGray)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
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
                    .padding(.horizontal, 20)
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
            Circle()
                .fill(Color.lightGray)
                .frame(width: 40, height: 40)
            
            Spacer()
            
            Text("Report")
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
        .padding(.horizontal, 20)
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
    private func loadCategories() async {
        let res = await IssueService.getCategories()
        if res.success, let list = res.data {
            categories = list.map { CategoryItem(id: $0.id, name: $0.name) }
        }
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
        guard !draft.category.isEmpty else { show("Please select a category") ; return }
        // description is optional; backend can handle empty and derive title

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
            createdIssueId = id
            navigateToEvidence = true
        } else {
            show(res.error ?? "Failed to create issue. Try again.")
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
