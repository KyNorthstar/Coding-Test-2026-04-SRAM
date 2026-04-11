//
//  ConsistencyScore.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky directing Claude 4.6 Sonnet on 2026-04-10.
//

import Foundation



/// Fallback weekly distance baseline (km) used when insufficient history exists to compute a meaningful personal average.
/// Approximates a moderate recreational cycling workload; intentionally conservative to avoid inflating scores for new users.
private let defaultBaselineDistanceKm: Double = 50



/// Cadence's proprietary riding consistency metric.
///
/// The score synthesizes three orthogonal dimensions of training behavior into a single
/// [0, 100] value using the **geometric mean** — chosen deliberately because it returns
/// 0 if *any* dimension is 0, reflecting the compound nature of true consistency.
///
/// ### Dimensions
/// - **Regularity**: Complement of the coefficient of variation across weekly ride counts.
///   Rewards even distribution over binge-and-rest patterns.
/// - **Volume**: Mean weekly distance in the window relative to the athlete's own 52-week
///   baseline. Rewards sustained load without penalizing athletes who are building up.
/// - **Recency**: Exponential decay (half-life = 4 weeks) over the evaluation window.
///   Rewards athletes who are consistent *now*, not just historically.
///
/// ### Explainability
/// All three component scores (0–1) are exposed on the returned struct so the UI can
/// show a breakdown — critical for making a proprietary metric feel trustworthy rather
/// than a black box.
///
/// Usage:
/// ```swift
/// let score = ConsistencyScore.compute(from: activities, weeks: 12)
/// print(score.value)       // 73.4
/// print(score.regularity)  // 0.87
/// ```
struct ConsistencyScore {
    
    /// Final blended score on a [0, 100] scale.
    let value: Double
    
    /// 0–1: How evenly rides are distributed week-over-week.
    let regularity: Double
    
    /// 0–1: Mean weekly volume relative to the athlete's own 52-week baseline.
    let volume: Double
    
    /// 0–1: Recency-weighted momentum; decays with a 4-week half-life.
    let recency: Double
}



// MARK: - Factory

extension ConsistencyScore {
    /// Computes the score from a flat activity list over the given evaluation window.
    ///
    /// - Parameters:
    ///   - activities: Full activity history (any date range — windowing is internal).
    ///   - weeks: Evaluation window in weeks. Defaults to 12.
    static func compute(from activities: [Activity], weeks: Int = 12) -> ConsistencyScore {
        let calendar = Calendar.current
        let now      = Date.now

        func weekStart(of date: Date) -> Date {
            calendar.date(from: calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: date))!
        }

        // 52-week volume baseline for normalization
        let baselineStart = calendar.date(byAdding: .weekOfYear, value: -52, to: now)!
        var weeklyVolume52: [Date: Double] = [:]
        for a in activities where a.isCyclingActivity && a.startDate >= baselineStart {
            weeklyVolume52[weekStart(of: a.startDate), default: 0] += a.distanceKm
        }
        let meanBaseline = weeklyVolume52.values.reduce(0, +) / max(Double(weeklyVolume52.count), 1)

        // Evaluation window
        let windowStart = calendar.date(byAdding: .weekOfYear, value: -weeks, to: now)!
        var weeklyRides:  [Date: Int]    = [:]
        var weeklyDist:   [Date: Double] = [:]
        for a in activities where a.isCyclingActivity && a.startDate >= windowStart {
            let ws = weekStart(of: a.startDate)
            weeklyRides[ws, default: 0] += 1
            weeklyDist[ws,  default: 0] += a.distanceKm
        }

        // All weeks in the window, including empty ones
        let allWeeks: [Date] = (0..<weeks).compactMap {
            calendar.date(byAdding: .weekOfYear, value: -$0, to: now).map { weekStart(of: $0) }
        }
        let counts  = allWeeks.map { Double(weeklyRides[$0] ?? 0) }
        let volumes = allWeeks.map { weeklyDist[$0]  ?? 0.0 }

        // MARK: Regularity
        let meanCount = counts.reduce(0, +) / Double(weeks)
        let variance  = counts.map { pow($0 - meanCount, 2) }.reduce(0, +) / Double(weeks)
        let cv        = meanCount > 0 ? sqrt(variance) / meanCount : 1.0
        let regularity = max(0, 1.0 - cv)

        // MARK: Volume
        let windowMean  = volumes.reduce(0, +) / Double(weeks)
        let baseline    = meanBaseline > 0 ? meanBaseline : defaultBaselineDistanceKm
        let volumeScore = min(windowMean / baseline, 1.5) / 1.5

        // MARK: Recency (exponential decay, half-life = 4 weeks)
        let lambda = log(2.0) / 4.0
        var num = 0.0, den = 0.0
        for (i, vol) in volumes.enumerated() {
            let w = exp(-lambda * Double(i))
            num += vol * w; den += w
        }
        let recencyRaw   = den > 0 ? num / den : 0
        let recencyScore = min(recencyRaw / baseline, 1.0)

        // MARK: Geometric mean → [0, 100]
        let geo = pow(regularity * volumeScore * recencyScore, 1.0 / 3.0)
        return ConsistencyScore(
            value:      geo * 100,
            regularity: regularity,
            volume:     volumeScore,
            recency:    recencyScore
        )
    }
}
