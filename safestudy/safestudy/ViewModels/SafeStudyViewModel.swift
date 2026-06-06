//
//  SafeStudyViewModel.swift
//  safestudy
//
//  Created by Katha on 3/22/26.
//
//
//  SafeStudyViewModel.swift
//  safestudy
//
//  Created by Katha on 3/22/26.
//

import Foundation
import CoreLocation
import Combine
import MapKit

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 25
    }

    func requestLocationAccess() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied or restricted.")
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location permission denied.")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.currentLocation = location
        }

        print("Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

struct OverpassResponse: Decodable {
    let elements: [OverpassElement]
}

struct OverpassElement: Decodable {
    let id: Int
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?
}

struct OverpassCenter: Decodable {
    let lat: Double
    let lon: Double
}

final class SafeStudyViewModel: ObservableObject {
    @Published var allSpots: [StudySpot] = []
    @Published var selectedCategory: String = "All"
    @Published var maxDistance: Double = 5.0
    @Published var selectedQuietness: String = "All"
    @Published var wifiOnly: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userLatitude: Double?
    @Published var userLongitude: Double?
    @Published var isUsingFallbackArea: Bool = false

    let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()

    private let fallbackLatitude = 33.4215
    private let fallbackLongitude = -111.9331
    private var hasFetchedOnce = false

    private let userAddedKey = "SafeStudy_UserAddedSpots"
    private let favoriteMetadataKey = "SafeStudy_FavoriteMetadata"

    init() {
        locationManager.$currentLocation
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self else { return }

                self.userLatitude = location.coordinate.latitude
                self.userLongitude = location.coordinate.longitude
                self.isUsingFallbackArea = false

                Task {
                    await self.fetchNearbyStudySpots(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                }
            }
            .store(in: &cancellables)
    }

    var filteredSpots: [StudySpot] {
        allSpots.filter { spot in
            let matchesCategory = selectedCategory == "All" || spot.category == selectedCategory
            let matchesDistance = spot.distance <= maxDistance
            let matchesQuietness = selectedQuietness == "All" || spot.quietness == selectedQuietness
            let matchesWiFi = !wifiOnly || spot.hasWiFi
            return matchesCategory && matchesDistance && matchesQuietness && matchesWiFi
        }
        .sorted { $0.distance < $1.distance }
    }

    var favoriteSpots: [StudySpot] {
        allSpots.filter { $0.isFavorite }
    }

    func requestLocation() {
        locationManager.requestLocationAccess()
    }

    func loadLiveASUFallbackIfNeeded() async {
        guard !hasFetchedOnce, userLatitude == nil, userLongitude == nil else { return }
        await MainActor.run {
            self.isUsingFallbackArea = true
        }
        await fetchNearbyStudySpots(latitude: fallbackLatitude, longitude: fallbackLongitude)
    }

    func toggleFavorite(for spot: StudySpot) {
        guard let index = allSpots.firstIndex(where: { $0.id == spot.id }) else { return }
        allSpots[index].isFavorite.toggle()
        saveStateToDisk()
    }

    func updateFavorite(for spot: StudySpot, rating: Int, tags: [String], notes: String) {
        guard let index = allSpots.firstIndex(where: { $0.id == spot.id }) else { return }
        allSpots[index].rating = rating
        allSpots[index].tags = tags
        allSpots[index].notes = notes
        allSpots[index].isFavorite = true
        saveStateToDisk()
    }

    func deleteFavorite(_ spot: StudySpot) {
        guard let index = allSpots.firstIndex(where: { $0.id == spot.id }) else { return }
        allSpots[index].isFavorite = false
        allSpots[index].rating = 0
        allSpots[index].tags = []
        allSpots[index].notes = ""

        if allSpots[index].isUserAdded {
            allSpots.remove(at: index)
        }

        saveStateToDisk()
    }

    func addCustomSpot(
        name: String,
        category: String,
        address: String,
        latitude: Double,
        longitude: Double,
        description: String,
        quietness: String,
        hasWiFi: Bool
    ) {
        let referenceLatitude = userLatitude ?? fallbackLatitude
        let referenceLongitude = userLongitude ?? fallbackLongitude

        let userLocation = CLLocation(latitude: referenceLatitude, longitude: referenceLongitude)
        let newLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distanceMiles = userLocation.distance(from: newLocation) / 1609.34

        let newSpot = StudySpot(
            id: UUID().uuidString,
            name: name,
            category: category,
            address: address,
            latitude: latitude,
            longitude: longitude,
            distance: distanceMiles,
            description: description,
            quietness: quietness,
            hasWiFi: hasWiFi,
            isFavorite: false,
            rating: 0,
            tags: [],
            notes: "",
            isUserAdded: true
        )

        allSpots.append(newSpot)
        allSpots.sort { $0.distance < $1.distance }
        saveStateToDisk()
    }

    func addCustomSpotUsingApproximateCurrentArea(
        name: String,
        category: String,
        address: String,
        description: String,
        quietness: String,
        hasWiFi: Bool
    ) {
        let lat = userLatitude ?? fallbackLatitude
        let lon = userLongitude ?? fallbackLongitude

        addCustomSpot(
            name: name,
            category: category,
            address: address,
            latitude: lat,
            longitude: lon,
            description: description,
            quietness: quietness,
            hasWiFi: hasWiFi
        )
    }

    func addCustomSpotUsingAddress(
        name: String,
        category: String,
        address: String,
        description: String,
        quietness: String,
        hasWiFi: Bool
    ) async -> Bool {
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            if let location = placemarks.first?.location {
                addCustomSpot(
                    name: name,
                    category: category,
                    address: address,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    description: description,
                    quietness: quietness,
                    hasWiFi: hasWiFi
                )
                return true
            } else {
                return false
            }
        } catch {
            print("Geocoding failed: \(error.localizedDescription)")
            return false
        }
    }

    @MainActor
    func fetchNearbyStudySpots(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        hasFetchedOnce = true

        do {
            let liveSpots = try await fetchOverpassSpots(latitude: latitude, longitude: longitude)

            if !liveSpots.isEmpty {
                let manualCampusSpots = makeManualCampusSpots(centerLatitude: latitude, centerLongitude: longitude)
                let persistedUserAddedSpots = loadUserAddedSpots()

                let combined = liveSpots + manualCampusSpots + persistedUserAddedSpots

                let unique = Dictionary(grouping: combined, by: { $0.name.lowercased() + "|" + $0.address.lowercased() })
                    .compactMap { $0.value.min(by: { $0.distance < $1.distance }) }
                    .sorted { $0.distance < $1.distance }

                preserveFavoriteState(from: allSpots, into: unique)
                isLoading = false
                errorMessage = nil
                saveStateToDisk()
                return
            }
        } catch {
            print("Overpass failed: \(error.localizedDescription)")
        }

        do {
            let appleSpots = try await fetchApplePlaces(latitude: latitude, longitude: longitude)

            let manualCampusSpots = makeManualCampusSpots(centerLatitude: latitude, centerLongitude: longitude)
            let persistedUserAddedSpots = loadUserAddedSpots()

            let combined = appleSpots + manualCampusSpots + persistedUserAddedSpots

            let unique = Dictionary(grouping: combined, by: { $0.name.lowercased() + "|" + $0.address.lowercased() })
                .compactMap { $0.value.min(by: { $0.distance < $1.distance }) }
                .sorted { $0.distance < $1.distance }

            if unique.isEmpty {
                allSpots = []
                errorMessage = "No nearby cafes or libraries found."
            } else {
                preserveFavoriteState(from: allSpots, into: unique)
                errorMessage = "Showing Apple Maps search results because Overpass is unavailable."
            }

            isLoading = false
            saveStateToDisk()
            return
        } catch {
            print("Apple place search failed: \(error.localizedDescription)")
        }

        let manualCampusSpots = makeManualCampusSpots(centerLatitude: latitude, centerLongitude: longitude)
        let persistedUserAddedSpots = loadUserAddedSpots()
        let fallbackSpots = (manualCampusSpots + persistedUserAddedSpots).sorted { $0.distance < $1.distance }

        if fallbackSpots.isEmpty {
            allSpots = []
            errorMessage = "Could not load nearby places."
        } else {
            preserveFavoriteState(from: allSpots, into: fallbackSpots)
            errorMessage = "Showing saved and core ASU study spots because live results could not be fully loaded."
        }

        isLoading = false
        saveStateToDisk()
    }

    private func fetchOverpassSpots(latitude: Double, longitude: Double) async throws -> [StudySpot] {
        let radius = 1800

        let query = """
        [out:json][timeout:25];
        (
          node["amenity"="cafe"](around:\(radius),\(latitude),\(longitude));
          way["amenity"="cafe"](around:\(radius),\(latitude),\(longitude));
          relation["amenity"="cafe"](around:\(radius),\(latitude),\(longitude));
          node["amenity"="library"](around:\(radius),\(latitude),\(longitude));
          way["amenity"="library"](around:\(radius),\(latitude),\(longitude));
          relation["amenity"="library"](around:\(radius),\(latitude),\(longitude));
        );
        out center;
        """

        let endpoints = [
            "https://overpass-api.de/api/interpreter",
            "https://overpass.kumi.systems/api/interpreter"
        ]

        for endpoint in endpoints {
            guard let url = URL(string: endpoint) else { continue }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = query.data(using: .utf8)
            request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 20

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    print("Overpass status code from \(endpoint): \(httpResponse.statusCode)")
                }

                guard let rawString = String(data: data, encoding: .utf8) else { continue }
                let trimmed = rawString.trimmingCharacters(in: .whitespacesAndNewlines)

                guard trimmed.first == "{" else {
                    print("Non-JSON response from \(endpoint):")
                    print(trimmed.prefix(300))
                    continue
                }

                let decoded = try JSONDecoder().decode(OverpassResponse.self, from: data)
                let centerLocation = CLLocation(latitude: latitude, longitude: longitude)

                let liveSpots: [StudySpot] = decoded.elements.compactMap { element in
                    let lat = element.lat ?? element.center?.lat
                    let lon = element.lon ?? element.center?.lon

                    guard let lat, let lon else { return nil }

                    let tags = element.tags ?? [:]
                    let amenity = tags["amenity"] ?? ""
                    guard amenity == "cafe" || amenity == "library" else { return nil }

                    let rawName = tags["name"]?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let name = (rawName?.isEmpty == false) ? rawName! : (amenity == "library" ? "Library" : "Cafe")
                    let category = amenity == "library" ? "Library" : "Cafe"

                    let addressParts = [
                        tags["addr:housenumber"],
                        tags["addr:street"],
                        tags["addr:city"]
                    ]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }

                    let address = addressParts.isEmpty ? "Tempe, AZ" : addressParts.joined(separator: " ")

                    let placeLocation = CLLocation(latitude: lat, longitude: lon)
                    let rawDistanceMiles = centerLocation.distance(from: placeLocation) / 1609.34
                    let distanceMiles = rawDistanceMiles.isFinite ? rawDistanceMiles : 0.0
                    let quietness = category == "Library" ? "Quiet" : "Moderate"

                    return StudySpot(
                        id: "\(element.id)-\(category)",
                        name: name,
                        category: category,
                        address: address,
                        latitude: lat,
                        longitude: lon,
                        distance: distanceMiles,
                        description: category == "Library"
                            ? "A nearby library that may offer a quieter environment for focused studying."
                            : "A nearby cafe that may be useful for casual studying and coffee breaks.",
                        quietness: quietness,
                        hasWiFi: true
                    )
                }

                if !liveSpots.isEmpty {
                    return liveSpots
                }
            } catch {
                print("Endpoint failed: \(endpoint)")
                print(error.localizedDescription)
            }
        }

        throw NSError(domain: "SafeStudy", code: 1001, userInfo: [NSLocalizedDescriptionKey: "All Overpass endpoints failed"])
    }

    private func fetchApplePlaces(latitude: Double, longitude: Double) async throws -> [StudySpot] {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )

        async let cafes = searchApplePlaces(query: "cafe", region: region, category: "Cafe")
        async let libraries = searchApplePlaces(query: "library", region: region, category: "Library")

        let results = try await cafes + libraries

        let unique = Dictionary(grouping: results, by: { $0.name.lowercased() + "|" + $0.address.lowercased() })
            .compactMap { $0.value.min(by: { $0.distance < $1.distance }) }
            .sorted { $0.distance < $1.distance }

        return unique
    }

    private func searchApplePlaces(query: String, region: MKCoordinateRegion, category: String) async throws -> [StudySpot] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        let response = try await MKLocalSearch(request: request).start()
        let centerLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)

        return response.mapItems.compactMap { item in
            let coordinate = item.placemark.coordinate
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distanceMiles = centerLocation.distance(from: location) / 1609.34

            let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? query.capitalized
            let address = item.placemark.title ?? "Tempe, AZ"
            let quietness = category == "Library" ? "Quiet" : "Moderate"

            return StudySpot(
                id: "apple-\(category.lowercased())-\(name)-\(coordinate.latitude)-\(coordinate.longitude)",
                name: name,
                category: category,
                address: address,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                distance: distanceMiles.isFinite ? distanceMiles : 0.0,
                description: category == "Library"
                    ? "A nearby library found using Apple Maps search."
                    : "A nearby cafe found using Apple Maps search.",
                quietness: quietness,
                hasWiFi: true
            )
        }
    }

    private func preserveFavoriteState(from oldSpots: [StudySpot], into newSpots: [StudySpot]) {
        let metadata = loadFavoriteMetadata()
        let oldByID = Dictionary(uniqueKeysWithValues: oldSpots.map { ($0.id, $0) })

        allSpots = newSpots.map { newSpot in
            var merged = newSpot

            if let old = oldByID[newSpot.id] {
                merged.isFavorite = old.isFavorite
                merged.rating = old.rating
                merged.tags = old.tags
                merged.notes = old.notes
                merged.isUserAdded = old.isUserAdded
            }

            if let saved = metadata[newSpot.id] {
                merged.isFavorite = saved.isFavorite
                merged.rating = saved.rating
                merged.tags = saved.tags
                merged.notes = saved.notes
                if !newSpot.isUserAdded {
                    merged.isUserAdded = saved.isUserAdded
                }
            }

            return merged
        }
    }

    private func makeManualCampusSpots(centerLatitude: Double, centerLongitude: Double) -> [StudySpot] {
        let center = CLLocation(latitude: centerLatitude, longitude: centerLongitude)

        let spots: [(String, String, String, Double, Double, String, String, Bool)] = [
            (
                "Noble Library",
                "Library",
                "601 E Tyler Mall, Tempe, AZ 85281",
                33.4207,
                -111.9343,
                "A reliable ASU library with study desks and a quieter environment.",
                "Quiet",
                true
            ),
            (
                "Hayden Library",
                "Library",
                "300 E Orange Mall, Tempe, AZ 85281",
                33.4197,
                -111.9301,
                "A central ASU study spot with lots of seating and strong campus WiFi.",
                "Quiet",
                true
            ),
            (
                "Starbucks at Memorial Union",
                "Cafe",
                "301 E Orange Mall, Tempe, AZ 85281",
                33.4177,
                -111.9345,
                "A convenient campus coffee stop for casual studying and quick breaks.",
                "Moderate",
                true
            ),
            (
                "Engrained Cafe",
                "Cafe",
                "301 E Orange Mall, Tempe, AZ 85281",
                33.4178,
                -111.9347,
                "A student-friendly cafe option in the Memorial Union area.",
                "Moderate",
                true
            )
        ]

        return spots.map { name, category, address, lat, lon, description, quietness, hasWiFi in
            let location = CLLocation(latitude: lat, longitude: lon)
            let distanceMiles = center.distance(from: location) / 1609.34

            return StudySpot(
                id: "manual-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))",
                name: name,
                category: category,
                address: address,
                latitude: lat,
                longitude: lon,
                distance: distanceMiles,
                description: description,
                quietness: quietness,
                hasWiFi: hasWiFi
            )
        }
    }

    private struct FavoriteMetadata: Codable {
        var id: String
        var isFavorite: Bool
        var rating: Int
        var tags: [String]
        var notes: String
        var isUserAdded: Bool
    }

    private func saveStateToDisk() {
        saveUserAddedSpots()
        saveFavoriteMetadata()
    }

    private func saveUserAddedSpots() {
        let userAdded = allSpots.filter { $0.isUserAdded }

        do {
            let data = try JSONEncoder().encode(userAdded)
            UserDefaults.standard.set(data, forKey: userAddedKey)
        } catch {
            print("Failed to save user-added spots: \(error.localizedDescription)")
        }
    }

    private func loadUserAddedSpots() -> [StudySpot] {
        guard let data = UserDefaults.standard.data(forKey: userAddedKey) else { return [] }

        do {
            return try JSONDecoder().decode([StudySpot].self, from: data)
        } catch {
            print("Failed to load user-added spots: \(error.localizedDescription)")
            return []
        }
    }

    private func saveFavoriteMetadata() {
        let favorites = allSpots.map {
            FavoriteMetadata(
                id: $0.id,
                isFavorite: $0.isFavorite,
                rating: $0.rating,
                tags: $0.tags,
                notes: $0.notes,
                isUserAdded: $0.isUserAdded
            )
        }

        do {
            let data = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(data, forKey: favoriteMetadataKey)
        } catch {
            print("Failed to save favorite metadata: \(error.localizedDescription)")
        }
    }

    private func loadFavoriteMetadata() -> [String: FavoriteMetadata] {
        guard let data = UserDefaults.standard.data(forKey: favoriteMetadataKey) else { return [:] }

        do {
            let decoded = try JSONDecoder().decode([FavoriteMetadata].self, from: data)
            return Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
        } catch {
            print("Failed to load favorite metadata: \(error.localizedDescription)")
            return [:]
        }
    }
}
