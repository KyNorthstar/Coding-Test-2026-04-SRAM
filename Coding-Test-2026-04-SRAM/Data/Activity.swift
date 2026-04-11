//
//  Activity.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import Foundation



/// A Strava summary activity as returned by `GET /v3/athlete/activities`.
///
/// Only consistency-relevant fields are decoded. Extend as needed without breaking
/// existing callers — `JSONDecoder` ignores unknown keys by default.
struct Activity: Equatable, Decodable, Identifiable {
    
    /// Strava's globally unique activity ID.
    let id: Int
    
    /// Athlete-supplied activity name.
    let name: String
    
    /// Total distance
    let distance: Measurement<UnitLength>
    
    /// Moving time in seconds.
    let movingTime: Int
    
    /// Cumulative elevation gain in meters.
    let totalElevationGain: Double
    
    /// Activity start time in the athlete's local timezone, as parsed from ISO8601.
    let startDate: Date
    
    /// Strava sport type string, e.g. `"Ride"`, `"VirtualRide"`, `"Run"`.
    let type: String
}



// MARK: - Computed Helpers

extension Activity {
    
    /// Distance in kilometers.
    var distanceKm: Double { distance.converted(to: .kilometers).value }
    
    /// Distance in miles.
    var distanceMiles: Double { distance.converted(to: .miles).value }
    
    /// Normalized to local midnight — used as the heatmap grid key.
    var startDay: Date { Calendar.current.startOfDay(for: startDate) }
    
    /// Returns `true` for activities that count toward cycling consistency metrics.
    var isCyclingActivity: Bool { type == "Ride" || type == "VirtualRide" }
}
