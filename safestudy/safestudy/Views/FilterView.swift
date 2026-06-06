//
//  FilterView.swift
//  safestudy
//
//  Created by Katha on 3/22/26.
//

import SwiftUI

struct FilterView: View {
    @EnvironmentObject var viewModel: SafeStudyViewModel

    let categories = [
        "All",
        "Cafe",
        "Library",
        "Study Room",
        "Lounge",
        "Classroom",
        "Lab",
        "Building Space",
        "Outdoor Spot",
        "Other"
    ]

    let quietnessOptions = ["All", "Quiet", "Moderate", "Busy"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Category")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            filterChip(
                                title: category,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Maximum Distance: \(String(format: "%.1f", viewModel.maxDistance)) mi")
                            .font(.headline)

                        Slider(value: $viewModel.maxDistance, in: 0.5...5.0, step: 0.5)

                        HStack {
                            Text("0.5 mi")
                            Spacer()
                            Text("5 mi")
                        }
                        .foregroundColor(.gray)
                    }

                    Text("Quietness")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            ForEach(quietnessOptions.prefix(2), id: \.self) { option in
                                filterChip(
                                    title: option,
                                    isSelected: viewModel.selectedQuietness == option
                                ) {
                                    viewModel.selectedQuietness = option
                                }
                            }
                        }

                        HStack {
                            ForEach(quietnessOptions.suffix(2), id: \.self) { option in
                                filterChip(
                                    title: option,
                                    isSelected: viewModel.selectedQuietness == option
                                ) {
                                    viewModel.selectedQuietness = option
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("WiFi Availability")
                            .font(.headline)

                        HStack {
                            filterChip(title: "All", isSelected: !viewModel.wifiOnly) {
                                viewModel.wifiOnly = false
                            }

                            filterChip(title: "WiFi Only", isSelected: viewModel.wifiOnly) {
                                viewModel.wifiOnly = true
                            }
                        }
                    }

                    Text("Matching Results: \(viewModel.filteredSpots.count)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Filter Study Spots")
        .navigationBarTitleDisplayMode(.inline)
    }

    func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Text(title)
            .foregroundColor(isSelected ? .white : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(14)
            .onTapGesture {
                action()
            }
    }
}
