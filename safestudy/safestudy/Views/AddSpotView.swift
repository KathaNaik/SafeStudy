//
//  AddSpotView.swift
//  safestudy
//
//  Created by Katha on 4/19/26.
//
import SwiftUI
import CoreLocation

struct AddSpotView: View {
    @EnvironmentObject var viewModel: SafeStudyViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "Study Room"
    @State private var address = ""
    @State private var description = ""
    @State private var quietness = "Moderate"
    @State private var hasWiFi = true
    @State private var isSaving = false
    @State private var errorMessage = ""

    let categories = [
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

    let quietnessOptions = ["Quiet", "Moderate", "Busy"]

    var body: some View {
        Form {
            Section("Spot Information") {
                TextField("Spot name", text: $name)

                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { item in
                        Text(item)
                    }
                }

                TextField("Building or address", text: $address)

                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...5)
            }

            Section("Study Environment") {
                Picker("Quietness", selection: $quietness) {
                    ForEach(quietnessOptions, id: \.self) { option in
                        Text(option)
                    }
                }

                Toggle("WiFi Available", isOn: $hasWiFi)
            }

            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button(isSaving ? "Saving..." : "Save Spot") {
                    Task {
                        await saveSpot()
                    }
                }
                .disabled(!isValidInput || isSaving)
            }
        }
        .navigationTitle("Add Study Spot")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveSpot() async {
        isSaving = true
        errorMessage = ""

        let finalDescription = description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "User-added study space on or near campus."
            : description

        let success = await viewModel.addCustomSpotUsingAddress(
            name: name,
            category: category,
            address: address,
            description: finalDescription,
            quietness: quietness,
            hasWiFi: hasWiFi
        )

        isSaving = false

        if success {
            dismiss()
        } else {
            viewModel.addCustomSpotUsingApproximateCurrentArea(
                name: name,
                category: category,
                address: address,
                description: finalDescription,
                quietness: quietness,
                hasWiFi: hasWiFi
            )
            dismiss()
        }
    }
}
