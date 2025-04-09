//
//  TafelListView.swift
//  TourTafel
//
//  Created by Lars Junker on 09.04.25.
//

import Foundation
import SwiftUI
import CoreLocation

struct TafelListView: View {
    @EnvironmentObject var locationManager: LocationManager
    var tafeln: [Tafel]
    var onSelect: (Tafel) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    var body: some View {
        List(filteredAndSortedTafeln) { tafel in
            Button {
                onSelect(tafel)
                dismiss()
            } label: {
                VStack(alignment: .leading) {
                    Text(tafel.title)
                        .font(.headline)
                    if let loc = locationManager.lastKnownLocation {
                        Text("\(distance(from: loc, to: tafel)) km entfernt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Alle Tafeln")
        .searchable(text: $searchText, prompt: "Tafel suchen")
    }

    private var filteredAndSortedTafeln: [Tafel] {
        let filtered = tafeln.filter {
            searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)
        }

        guard let loc = locationManager.lastKnownLocation else {
            return filtered.sorted { $0.title < $1.title }
        }

        return filtered.sorted {
            distance(from: loc, to: $0) < distance(from: loc, to: $1)
        }
    }

    private func distance(from loc: CLLocation, to tafel: Tafel) -> Double {
        let target = CLLocation(latitude: tafel.latitude, longitude: tafel.longitude)
        return loc.distance(from: target) / 1000.0
    }
}

