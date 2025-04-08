//
//  LocationManager.swift
//  TourTafel
//
//  Created by Lars Junker on 08.04.25.
//

import Foundation
import CoreLocation
import Combine
import SwiftData

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    @Published var nearbyTafel: Tafel?
    var tafeln: [Tafel] = [] {
        didSet {
            print("INFO: Tafeln updated: \(tafeln.count)")
            lastKnownLocation.map(checkNearbyTafeln)
        }
    }
    
    private var lastKnownLocation: CLLocation?
    
    override init() {
        super.init( )
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization( )
        manager.startUpdatingLocation( )
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        
        lastKnownLocation = loc
        checkNearbyTafeln(at: loc)
    }
    
    private func checkNearbyTafeln(at loc: CLLocation) {
        for tafel in tafeln {
            let dist = loc.distance(from: CLLocation(latitude: tafel.latitude, longitude: tafel.longitude))
            if dist < 1000 {
                self.nearbyTafel = tafel
                return
            }
        }
        self.nearbyTafel = nil
    }
}
