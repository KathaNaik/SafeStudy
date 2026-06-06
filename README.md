# SafeStudy

SafeStudy is an iOS app that helps students discover and save good places to study nearby. It combines location-based search, maps, filtering, favorites, and custom user-added study spaces into one mobile experience.

## Overview

Students often need different kinds of study spaces depending on the situation. Sometimes they want a quiet library, sometimes a cafe with WiFi, and sometimes a study room, lounge, classroom, or another informal space inside a building. SafeStudy is designed to make it easier to find, organize, and revisit those places.

The app uses SwiftUI and follows the MVVM architecture pattern. It integrates maps, location services, live place search, and local persistence to create a practical campus-focused study spot finder.

## Features

- View nearby study spots on a map
- Search study spots by name, category, or address
- Filter spots by category, distance, quietness, and WiFi availability
- View detailed information about each study spot
- Save favorite spots
- Edit favorites with notes, ratings, and tags
- Open directions in Apple Maps
- Add custom study spots such as:
  - Study rooms
  - Lounges
  - Classrooms
  - Labs
  - Building spaces
  - Outdoor spots
- Persist favorites and custom spots across app restarts

## Tech Stack

- **SwiftUI** for the user interface
- **MVVM architecture** for separation of UI, logic, and data
- **CoreLocation** for user location access
- **MapKit** for map display and navigation support
- **Overpass API** for live nearby cafes and libraries
- **Apple Maps / MKLocalSearch** as a fallback for place search
- **UserDefaults** for local persistence of favorites and user-added spots
- **Combine** for observable state updates

## Architecture

SafeStudy uses the **Model-View-ViewModel (MVVM)** pattern.

### View Layer
Contains the SwiftUI screens:
- `ContentView`
- `HomeView`
- `SpotDetailView`
- `SavedFavoritesView`
- `EditFavoriteView`
- `FilterView`
- `AddSpotView`

### ViewModel Layer
Contains:
- `SafeStudyViewModel`
- `LocationManager`

The ViewModel manages:
- app state
- filtering logic
- favorites
- custom spot creation
- API calls
- persistence
- interaction with external services

### Model Layer
Contains:
- `StudySpot`
- Overpass API decoding models:
  - `OverpassResponse`
  - `OverpassElement`
  - `OverpassCenter`

## How It Works

1. The app requests the user’s location using CoreLocation.
2. The map centers around the current location if available.
3. Nearby places are fetched using live search.
4. Results are displayed on the map and in a list.
5. The user can search, filter, favorite, and edit spots.
6. If a desired place is missing, the user can manually add a custom study spot.
7. Favorites and custom spots are stored locally and restored when the app reopens.

## Screens

### Home Screen
Displays:
- app title
- search bar
- filter button
- add spot button
- map with markers
- nearby study spot cards

### Spot Detail Screen
Displays:
- spot name and category
- address and distance
- description
- quietness and WiFi info
- save favorite button
- open in Apple Maps button

### Saved Favorites Screen
Displays:
- all saved favorite spots
- edit option
- delete option

### Edit Favorite Screen
Lets the user:
- add a rating
- add tags
- write personal notes

### Filter Screen
Lets the user filter by:
- category
- distance
- quietness
- WiFi availability

### Add Spot Screen
Lets the user create a custom study spot by entering:
- spot name
- category
- building or address
- description
- quietness
- WiFi availability

## Installation

### Requirements
- Xcode 16 or above
- iOS 17 or above

### Steps
1. Clone or download the project
2. Open the project in Xcode
3. Make sure the app target includes all source files
4. Add the location usage key in `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>SafeStudy uses your location to find nearby cafes and libraries for studying.</string>
