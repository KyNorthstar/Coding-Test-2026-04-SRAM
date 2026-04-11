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
struct Activity: Equatable, Identifiable {
    
    /// Strava's globally unique activity ID.
    let id: Int
    
    /// Athlete-supplied activity name.
    let name: String
    
    /// Total distance
    let distance: Measurement<UnitLength>
    
    /// How long the athlete spent moving in theactivity
    let movingTime: Measurement<UnitDuration>
    
    /// Cumulative elevation gain
    let totalElevationGain: Measurement<UnitLength>
    
    /// Activity start time in the athlete's local timezone, as parsed from ISO8601.
    let startDate: Date
    
    /// Strava sport type string, e.g. `"Ride"`, `"VirtualRide"`, `"Run"`.
    let type: String
}



extension Activity: Decodable {
    enum CodingKeys: CodingKey {
        case id
        case name
        case distance
        case movingTime
        case totalElevationGain
        case startDate
        case type
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id                 =              try container.decode(Int.self,    forKey: .id)
        self.name               =              try container.decode(String.self, forKey: .name)
        self.distance           = .init(value: try container.decode(Double.self, forKey: .distance), unit: .meters)
        self.movingTime         = .init(value: try container.decode(Double.self, forKey: .movingTime), unit: .seconds)
        self.totalElevationGain = .init(value: try container.decode(Double.self, forKey: .totalElevationGain), unit: .meters)
        self.startDate          =              try container.decode(Date.self,   forKey: .startDate)
        self.type               =              try container.decode(String.self, forKey: .type)
    }
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
