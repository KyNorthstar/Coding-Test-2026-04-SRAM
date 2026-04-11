//
//  Activity + demo.swift
//  Cadence
//
//  Created by Ky on 2026-04-10.
//

import Foundation



extension Activity {
    /// A random activity taking place the given time interval since now
    ///
    /// All other fields of this activity are randomized
    ///
    /// - Parameter timeIntervalSinceNow: When the activity (will have) took place, expressed as a `TimeInterval` where positive numbers indicate an activity in the future.
    static nonisolated func random(timeIntervalSinceNow: TimeInterval) -> Self {
        let restDay = UInt8.random(in: 1...7) < 3 // A few days of rest per week is good
        return Activity(
            id:                 .random(in: 0 ... .max),
            name:               "Demo activity",
            distance:           .init(value: restDay ? 0 : .random(in: 0...20),   unit: .kilometers),
            movingTime:         .init(value: restDay ? 0 : .random(in: 0...4),    unit: .hours),
            totalElevationGain: .init(value: restDay ? 0 : .random(in: -1 ... 1), unit: .kilometers),
            startDate:          .init(timeIntervalSinceNow: timeIntervalSinceNow),
            type:               "Demo")
    }
    
    
    /// A random activity taking place the given amount of time into the past
    ///
    /// - Parameter timeAgo: How long ago the activity took place.
    ///                      Positive values indivate an activity in the past, so if you pass `Measurement(value: 7, unit: .days)`, that means the activity took place 7 days ago.
    static nonisolated func random(timeAgo: Measurement<UnitDuration>) -> Self {
        random(timeIntervalSinceNow: -timeAgo.converted(to: .seconds).value)
    }
    
    
    /// A random activity taking place the given number of days ago
    ///
    /// - Parameter daysAgo: The number of (ephemeris) days into the past that the fake activity "took place"
    static nonisolated func random(daysAgo: UInt) -> Self {
        random(timeAgo: .init(value: Double(daysAgo) * 24, unit: .hours))
    }
}



extension [Activity] {
    /// Generates an array of consecutive past activities, each with random values
    ///
    /// - Parameter pastDaysToGenerate: The amount of days of activity to generate.
    /// - Returns: An array of `pastDaysToGenerate` number of consecutive activities where the most recent one is today
    static func random(pastDaysToGenerate: UInt16) -> Self {
        (0 == pastDaysToGenerate)
            ? []
            : (1 ... pastDaysToGenerate)
                .lazy
                .reversed()
                .map(UInt.init)
                .map(Activity.random(daysAgo:))
    }
}
