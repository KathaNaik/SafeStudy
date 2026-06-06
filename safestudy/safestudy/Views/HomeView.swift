//
//  HomeView.swift
//  safestudy
//
//  Created by Katha on 3/22/26.
//

import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject var viewModel: SafeStudyViewModel
    @State private var searchText = ""
    @State private var showAddSpotView = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.4215, longitude: -111.9331),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )

    private var displayedSpots: [StudySpot] {
        let base = viewModel.filteredSpots

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return base
        }

        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerSection
                    searchSection
                    mapSection
                    statusSection
                    titleSection
                    cardsSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            updateCameraIfPossible()
            viewModel.requestLocation()

            try? await Task.sleep(nanoseconds: 2_000_000_000)

            if viewModel.userLatitude == nil || viewModel.userLongitude == nil {
                await viewModel.loadLiveASUFallbackIfNeeded()
                updateCameraIfPossible()
            }
        }
        .onChange(of: viewModel.userLatitude) { _, _ in
            updateCameraIfPossible()
        }
        .onChange(of: viewModel.userLongitude) { _, _ in
            updateCameraIfPossible()
        }
        .sheet(isPresented: $showAddSpotView) {
            NavigationStack {
                AddSpotView()
                    .environmentObject(viewModel)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SafeStudy")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Find your next study space")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                showAddSpotView = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.primary)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.shadow, radius: 8, x: 0, y: 4)
            }
        }
    }

    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textSecondary)

                TextField("Search study spots", text: $searchText)
                    .foregroundColor(AppTheme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(AppTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

            NavigationLink {
                FilterView()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.primary)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.shadow, radius: 8, x: 0, y: 4)
            }
        }
    }

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            if let lat = viewModel.userLatitude, let lon = viewModel.userLongitude {
                Marker("You", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                    .tint(AppTheme.primary)
            }

            ForEach(displayedSpots) { spot in
                Marker(spot.name, coordinate: spot.coordinate)
                    .tint(colorForCategory(spot.category))
            }
        }
        .frame(height: 245)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if viewModel.userLatitude == nil || viewModel.userLongitude == nil {
                Text(viewModel.isUsingFallbackArea
                     ? "Using live ASU Tempe area results because device location is unavailable."
                     : "Waiting for location...")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }

            if viewModel.isLoading {
                ProgressView("Finding nearby study spots...")
                    .tint(AppTheme.primary)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nearby Study Spots")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text("Showing \(displayedSpots.count) results")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardsSection: some View {
        LazyVStack(spacing: 14) {
            ForEach(displayedSpots) { spot in
                NavigationLink {
                    SpotDetailView(spot: spot)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.softCard)
                                .frame(width: 58, height: 58)

                            Image(systemName: iconForCategory(spot.category))
                                .font(.title3)
                                .foregroundColor(colorForCategory(spot.category))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(spot.name)
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            Text(spot.category)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)

                            HStack(spacing: 8) {
                                Label(String(format: "%.2f mi away", spot.distance), systemImage: "location")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)

                                if spot.hasWiFi {
                                    Text("WiFi")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.softCard)
                                        .foregroundColor(AppTheme.primaryDark)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.8))
                    }
                    .padding(16)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 5)
                }
            }
        }
    }

    private func updateCameraIfPossible() {
        let lat = viewModel.userLatitude ?? 33.4215
        let lon = viewModel.userLongitude ?? -111.9331

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )

        cameraPosition = .region(region)
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Cafe": return "cup.and.saucer.fill"
        case "Library": return "books.vertical.fill"
        case "Study Room": return "door.left.hand.open"
        case "Lounge": return "sofa.fill"
        case "Classroom": return "rectangle.and.pencil.and.ellipsis"
        case "Lab": return "desktopcomputer"
        case "Building Space": return "building.2.fill"
        case "Outdoor Spot": return "tree.fill"
        default: return "mappin.circle.fill"
        }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Cafe": return AppTheme.accent
        case "Library": return .purple
        case "Study Room": return .blue
        case "Lounge": return .mint
        case "Classroom": return .green
        case "Lab": return .indigo
        case "Building Space": return .brown
        case "Outdoor Spot": return .teal
        default: return AppTheme.primary
        }
    }
}
