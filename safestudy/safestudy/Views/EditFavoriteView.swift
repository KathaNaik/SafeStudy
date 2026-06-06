//
//  EditFavoriteView.swift
//  safestudy
//
//  Created by Katha on 3/22/26.
//
import SwiftUI

struct EditFavoriteView: View {
    @EnvironmentObject var viewModel: SafeStudyViewModel
    @Environment(\.dismiss) private var dismiss

    let spot: StudySpot

    @State private var rating = 0
    @State private var notes = ""
    @State private var selectedTags: Set<String> = []

    let allTags = ["Quiet", "Good WiFi", "Crowded", "Comfortable", "Long Stay"]

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 24) {
                Text(spot.name)
                    .font(.title)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Rating")
                        .font(.headline)

                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    rating = star
                                }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Tags")
                        .font(.headline)

                    FlexibleTagView(tags: allTags, selectedTags: $selectedTags)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Personal Notes")
                        .font(.headline)

                    TextEditor(text: $notes)
                        .frame(height: 140)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                }

                Button {
                    viewModel.updateFavorite(
                        for: spot,
                        rating: rating,
                        tags: Array(selectedTags),
                        notes: notes
                    )
                    dismiss()
                } label: {
                    Text("Save Changes")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            .padding()

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Edit Favorite")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            rating = spot.rating
            notes = spot.notes
            selectedTags = Set(spot.tags)
        }
    }
}

struct FlexibleTagView: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(chunked(tags, into: 3), id: \.self) { row in
                HStack {
                    ForEach(row, id: \.self) { tag in
                        Text(tag)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedTags.contains(tag) ? Color.blue.opacity(0.18) : Color(.systemGray6))
                            .cornerRadius(20)
                            .onTapGesture {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                    }
                }
            }
        }
    }

    private func chunked(_ array: [String], into size: Int) -> [[String]] {
        stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<min($0 + size, array.count)])
        }
    }
}
