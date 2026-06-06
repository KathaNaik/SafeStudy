//
//  SavedFavoritesView.swift
//  safestudy
//
//  Created by Katha on 3/22/26.
//
import SwiftUI

struct SavedFavoritesView: View {
    @EnvironmentObject var viewModel: SafeStudyViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved Favorites")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Your personal study picks")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.horizontal)

                if viewModel.favoriteSpots.isEmpty {
                    Spacer()
                    Text("No favorites saved yet.")
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(viewModel.favoriteSpots) { spot in
                                HStack {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(AppTheme.softCard)
                                                .frame(width: 52, height: 52)

                                            Image(systemName: iconForCategory(spot.category))
                                                .foregroundColor(colorForCategory(spot.category))
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(spot.name)
                                                .font(.headline)
                                                .foregroundColor(AppTheme.textPrimary)

                                            if !spot.tags.isEmpty {
                                                Text(spot.tags.joined(separator: ", "))
                                                    .font(.caption)
                                                    .foregroundColor(AppTheme.textSecondary)
                                            }
                                        }
                                    }

                                    Spacer()

                                    NavigationLink {
                                        EditFavoriteView(spot: spot)
                                    } label: {
                                        Image(systemName: "pencil")
                                            .foregroundColor(AppTheme.primary)
                                            .font(.title3)
                                    }

                                    Button {
                                        viewModel.deleteFavorite(spot)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red.opacity(0.8))
                                            .font(.title3)
                                    }
                                }
                                .padding(16)
                                .background(AppTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(AppTheme.border, lineWidth: 1)
                                )
                                .shadow(color: AppTheme.shadow, radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .padding(.top, 14)
        }
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
