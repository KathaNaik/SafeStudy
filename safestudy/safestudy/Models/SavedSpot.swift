//
//  SavedSpot.swift
//  safestudy
//
//  Created by Katha on 4/19/26.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class SavedSpot {
    var id: String
    var name: String
    var category: String
    var address: String
    var latitude: Double
    var longitude: Double
    var distance: Double
    var spotDescription: String
    var rating: Int
    var notes: String
    var tagsText: String
    var createdAt: Date

    init(
        id: String,
        name: String,
        category: String,
        address: String,
        latitude: Double,
        longitude: Double,
        distance: Double,
        spotDescription: String,
        rating: Int = 0,
        notes: String = "",
        tagsText: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
        self.spotDescription = spotDescription
        self.rating = rating
        self.notes = notes
        self.tagsText = tagsText
        self.createdAt = createdAt
    }

    var tags: [String] {
        get {
            if tagsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return []
            }
            return tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            tagsText = newValue.joined(separator: ", ")
        }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
