//
//  LocationFetcher.swift
//  SwiftHashing
//
//  Created by Mads on 23/11/2025.
//

public struct Location {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Responsible for fetching GPS locations
public protocol LocationFetcher {
    func currentLocation() -> Location
}
