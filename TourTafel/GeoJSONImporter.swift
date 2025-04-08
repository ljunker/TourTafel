//
//  GeoJSONImporter.swift
//  TourTafel
//
//  Created by Lars Junker on 08.04.25.
//

import Foundation
import SwiftData

struct GeoFeatureCollection: Decodable {
    let features: [GeoFeature]
}

struct GeoFeature: Decodable {
    let geometry: Geometry
    let properties: Properties
    
    struct Geometry: Decodable {
        let coordinates: [Double]
    }
    
    struct Properties: Decodable {
        let name: String?
    }
}

class GeoJSONImporter {
    static func importTafeln(from fileName: String, into context: ModelContext) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let collection = try? JSONDecoder().decode(GeoFeatureCollection.self, from: data) else {
            print("ERROR: Failed to load GeoJSON")
            return
        }
        
        for feature in collection.features {
            guard let name = feature.properties.name,
                  feature.geometry.coordinates.count == 2 else {
                continue
            }
            
            let lon = feature.geometry.coordinates[0]
            let lat = feature.geometry.coordinates[1]
            
            let tafel = Tafel(title: name,
                              info: "Auto-Imported from OSM",
                              latitude: lat,
                              longitude: lon
            )
            context.insert(tafel)
        }
        print("INFO: Imported \(collection.features.count) entries.")
    }
}
