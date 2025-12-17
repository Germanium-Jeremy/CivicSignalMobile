//
//  MapView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 27/11/2025.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showLegend = false
    
    // Default coordinates for Kigali, Rwanda
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -1.9499, longitude: 30.0588),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Map Container
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: viewModel.issues) { issue in
                            MapAnnotation(coordinate: CLLocationCoordinate2D(
                                latitude: issue.location?.latitude ?? -1.9499,
                                longitude: issue.location?.longitude ?? 30.0588
                            )) {
                                IssueMarker(issue: issue) {
                                    // Navigate to issue details
                                    // This would need navigation setup
                                }
                            }
                        }
                        .edgesIgnoringSafeArea(.bottom)
                    }
                    
                    // Legend Toggle Button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: { showLegend.toggle() }) {
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.primaryBlue)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .onAppear { Task { await viewModel.fetchIssues() } }
        .sheet(isPresented: $showLegend) {
            MapLegendView()
        }
    }
    
    private var searchBar: some View {
        HStack {
            TextField("Search Location", text: .constant(""))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.lightGray)
                .cornerRadius(20)
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.neutralGray)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Issue Marker
struct IssueMarker: View {
    let issue: IssueDTO
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
    }
    
    private var statusColor: Color {
        switch issue.status {
        case "submitted": return .red
        case "acknowledged": return .orange
        case "pending": return .yellow
        case "resolved": return .green
        default: return .gray
        }
    }
}

// MARK: - Map Legend
struct MapLegendView: View {
    @Environment(\.dismiss) private var dismiss
    
    let statusColors = [
        ("Submitted", Color.red),
        ("Acknowledged", Color.orange),
        ("Pending", Color.yellow),
        ("Resolved", Color.green)
    ]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Issue Status Legend")
                    .font(AppFont.title2)
                    .foregroundColor(.almostBlack)
                    .padding(.top)
                
                ForEach(statusColors, id: \.0) { status, color in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(color)
                            .frame(width: 16, height: 16)
                        
                        Text(status)
                            .font(AppFont.body)
                            .foregroundColor(.almostBlack)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - MapViewModel
@MainActor
class MapViewModel: ObservableObject {
    @Published var issues: [IssueDTO] = []
    @Published var isLoading = false
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -1.9499, longitude: 30.0588),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    func fetchIssues() async {
        isLoading = true
        defer { isLoading = false }
        
        let result = await IssueService.getAllPublicIssues(limit: 100)
        
        if result.success, let response = result.data {
            self.issues = response.data.issues
            updateRegionToFitIssues()
        } else {
            print("Failed to fetch public issues: \(result.error ?? "Unknown error")")
        }
    }
    
    private func updateRegionToFitIssues() {
        guard !issues.isEmpty else { return }
        
        let validCoords: [CLLocationCoordinate2D] = issues.compactMap { issue in
            guard let loc = issue.location,
                  let lat = loc.latitude,
                  let lon = loc.longitude else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        guard !validCoords.isEmpty else { return }
        
        let minLat = validCoords.map(\.latitude).min()!
        let maxLat = validCoords.map(\.latitude).max()!
        let minLon = validCoords.map(\.longitude).min()!
        let maxLon = validCoords.map(\.longitude).max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

#Preview {
    MapView()
}
