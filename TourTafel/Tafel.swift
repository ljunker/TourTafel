//
//  Tafel.swift
//  TourTafel
//
//  Created by Lars Junker on 08.04.25.
//

import Foundation
import SwiftData

@Model
class Tafel {
    var id: UUID
    var title: String
    var info: String
    var latitude: Double
    var longitude: Double
    
    init(id: UUID = UUID(), title: String, info: String, latitude: Double, longitude: Double) {
        self.id = id
        self.title = title
        self.info = info
        self.latitude = latitude
        self.longitude = longitude
    }
}
