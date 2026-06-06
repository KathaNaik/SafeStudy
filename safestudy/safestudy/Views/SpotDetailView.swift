//
//  SpotDetailView.swift
//  safestudy
//
//  Created by Katha on 3/22/26.
//

import SwiftUI
import MapKit

struct SpotDetailView: View {
    @EnvironmentObject var viewModel: SafeStudyViewModel
    let spot: StudySpot

    var currentSpot: StudySpot {
        viewModel.allSpots.first(where: { $0.id == spot.id }) ?? spot
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(AppTheme.softCard)
                                    .frame(width: 72, height: 72)

                                Image(systemName: iconForCategory(currentSpot.category))
                                    .font(.title2)
                                    .foregroundColor(colorForCategory(currentSpot.category))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(currentSpot.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.textPrimary)

                                Text(currentSpot.category)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(currentSpot.address)
                                .foregroundColor(AppTheme.textSecondary)

                            Text(String(format: "%.2f miles away", currentSpot.distance))
                                .foregroundColor(AppTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("About")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textPrimary)

                            Text(currentSpot.description)
                                .foregroundColor(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Study Environment")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textPrimary)

                            Text("Quietness: \(currentSpot.quietness)")
                            Text("WiFi: \(currentSpot.hasWiFi ? "Available" : "Not Available")")
                        }
                        .foregroundColor(AppTheme.textSecondary)

                        Button {
                            viewModel.toggleFavorite(for: currentSpot)
                        } label: {
                            HStack {
                                Image(systemName: currentSpot.isFavorite ? "heart.fill" : "heart")
                                Text(currentSpot.isFavorite ? "Saved to Favorites" : "Save Favorite")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primary)
                            .cornerRadius(18)
                        }

                        Button {
                            openInMaps(for: currentSpot)
                        } label: {
                            HStack {
                                Image(systemName: "paperplane")
                                Text("Open in Apple Maps")
                            }
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.softCard)
                            .cornerRadius(18)
                        }
                    }
                    .padding(20)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .padding(.top, 18)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Study Spot Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openInMaps(for spot: StudySpot) {
        let coordinate = CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = spot.name
        item.openInMaps()
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
