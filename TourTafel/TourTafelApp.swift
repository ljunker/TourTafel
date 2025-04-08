//
//  TourTafelApp.swift
//  TourTafel
//
//  Created by Lars Junker on 08.04.25.
//

import SwiftUI
import SwiftData

@main
struct TourTafelApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Tafel.self)
    }
}
