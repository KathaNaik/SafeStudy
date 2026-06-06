//
//  StudySpot.swift
//  safestudy
//
//  Created by Katha on 3/22/26.
//
import Foundation
import CoreLocation

struct StudySpot: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var category: String
    var address: String
    var latitude: Double
    var longitude: Double
    var distance: Double
    var description: String
    var quietness: String
    var hasWiFi: Bool

    var isFavorite: Bool = false
    var rating: Int = 0
    var tags: [String] = []
    var notes: String = ""
    var isUserAdded: Bool = false

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
