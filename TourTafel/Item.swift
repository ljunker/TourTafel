//
//  Item.swift
//  TourTafel
//
//  Created by Lars Junker on 08.04.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
