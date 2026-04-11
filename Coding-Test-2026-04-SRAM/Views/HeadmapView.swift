//
//  HeadmapView.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//  Portions of this file were created using Claude 4.6 Sonnet
//

import Combine
import SwiftUI



private let cellSize:    CGFloat = 44
private let cellSpacing: CGFloat =  5



/// The hero screen — a 52-week riding heatmap with month labels and an orange intensity ramp.
///
/// Layout: a horizontal stack of [month label column | LazyVGrid]. Month label frames
/// are sized to `weekCount × rowHeight` so each label centers within its month without
/// any manual offset arithmetic. Color is computed in HSB so a single function produces
/// the full peach → amber → burnt-orange ramp without hardcoded swatches.
struct HeatmapView: View {
    
    @State
    private var cells: [Cell] = []
    
    @State
    private var monthSections: [MonthSection] = []
    
    @State
    private var consistencyScore: ConsistencyScore?
    
    @State private var selectedCell: Cell?
    
    private let activities: [Activity]
    
    
    init(activities: [Activity]) {
        self.activities = activities
    }
    
    
    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 8) {
                monthLabels
                grid
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
    }
}



// MARK: - Subviews
private extension HeatmapView {
    var monthLabels: some View {
        VStack(alignment: .center, spacing: 0) {
            ForEach(monthSections) { section in
                Text(section.name)
                    .font(.system(size: 13, weight: .semibold))
                    .rotationEffect(.degrees(-90))
                    .frame(
                        width: 28,
                        height: CGFloat(section.weekCount) * rowHeight - cellSpacing,
                    )
                    .clipped()
            }
        }
    }
    
    
    var grid: some View {
        let columns = Array(
            repeating: GridItem(.fixed(cellSize), spacing: cellSpacing),
            count: 7,
        )
        return LazyVGrid(columns: columns, spacing: cellSpacing) {
            ForEach(cells) { cell in
                RoundedRectangle(cornerRadius: 10)
                    .fill(color(for: cell.intensity))
                    .frame(width: cellSize, height: cellSize)
                    .onTapGesture { selectedCell = cell }
            }
        }
        .popover(item: $selectedCell) { CellPopover(cell: $0) }
    }
    
    
    var loadingOverlay: some View {
        ProgressView()
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    
    /// Maps intensity [0, 1] to the orange ramp visible in the mockup.
    ///
    /// HSB interpolation gives a perceptually smooth ramp from near-white peach
    /// through amber to burnt orange-brown, without needing discrete color stops.
    private func color(for intensity: Double) -> Color {
        guard intensity > 0 else { return Color(.systemGray5) }
        return Color(
            hue:        0.085 - intensity * 0.02,
            saturation: 0.45  + intensity * 0.55,
            brightness: 1.0   - intensity * 0.32,
        )
    }
    
    
    /// Row height as seen by the month label column — must account for spacing
    /// so label frames stay in sync with grid rows.
    private var rowHeight: CGFloat {
        cellSize + cellSpacing
    }
}


private extension HeatmapView {
    
    /// One cell in the 52×7 grid.
    ///
    /// `intensity` is pre-normalized to [0, 1] against the busiest single day
    /// in the window, so the view only decides how to paint it.
    struct Cell: Identifiable {
        let id: Date
        let date: Date
        let intensity: Double
        let distance: Measurement<UnitLength>
        let rideCount: Int
    }
    
    
    
    /// Drives the height of a month label in the left-hand column.
    ///
    /// Because each label frame is `weekCount × rowHeight`, the label centers
    /// within its month purely through SwiftUI's frame alignment — no offsets needed.
    struct MonthSection: Identifiable {
        let id: Date
        let name: String
        let weekCount: Int
    }
}



// MARK: - Private functionality

private extension HeatmapView {
    func build() {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: .now)
        
        // O(n) lookup tables
        var distByDay:  [Date: Measurement<UnitLength>] = [:]
        var countByDay: [Date: Int] = [:]
        for a in activities where a.isCyclingActivity {
            let day = a.startDay
            distByDay[day]  = (distByDay[day] ?? .init(value: 0, unit: .meters)) + a.distance
            countByDay[day, default: 0] += 1
        }
        
        let maxKm = distByDay.values
            .map { $0.converted(to: .kilometers).value }
            .max() ?? 1
        
        // Align origin to the start of the week 52 weeks ago, so columns
        // map cleanly to weekdays regardless of when the app is launched.
        let weekdayOfToday = calendar.component(.weekday, from: today)
        let daysBack       = (weekdayOfToday - calendar.firstWeekday + 7) % 7
        let startOfWeek    = calendar.date(byAdding: .day, value: -daysBack, to: today)!
        let origin         = calendar.date(byAdding: .weekOfYear, value: -51, to: startOfWeek)!
        
        cells = (0 ..< 364).map { offset in
            let date      = calendar.date(byAdding: .day, value: offset, to: origin)!
            let dist      = distByDay[date] ?? .init(value: 0, unit: .meters)
            let count     = countByDay[date] ?? 0
            let intensity = dist.converted(to: .kilometers).value / maxKm
            return Cell(id: date, date: date, intensity: intensity, distance: dist, rideCount: count)
        }
        
        monthSections    = buildMonthSections(origin: origin, calendar: calendar)
        consistencyScore = ConsistencyScore.compute(from: activities)
    }
    
    private func buildMonthSections(origin: Date, calendar: Calendar) -> [MonthSection] {
        let formatter    = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        var sections:      [MonthSection] = []
        var sectionStart   = origin
        var sectionMonth   = calendar.component(.month, from: origin)
        var sectionYear    = calendar.component(.year,  from: origin)
        var weekCount      = 0
        
        for weekIndex in 0 ..< 52 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: origin)!
            let month     = calendar.component(.month, from: weekStart)
            let year      = calendar.component(.year,  from: weekStart)
            
            if month != sectionMonth || year != sectionYear {
                sections.append(.init(
                    id:        sectionStart,
                    name:      formatter.string(from: sectionStart),
                    weekCount: weekCount,
                ))
                sectionStart = weekStart
                sectionMonth = month
                sectionYear  = year
                weekCount    = 1
            } else {
                weekCount += 1
            }
        }
        
        sections.append(.init(
            id:        sectionStart,
            name:      formatter.string(from: sectionStart),
            weekCount: weekCount,
        ))
        
        return sections
    }
}


// MARK: - CellPopover

private extension HeatmapView {
    struct CellPopover: View {
        
        let cell: Cell
        
        private static let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .medium
            return f
        }()
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(Self.formatter.string(from: cell.date))
                    .font(.headline)
                if cell.rideCount > 0 {
                    Label("\(cell.rideCount) ride\(cell.rideCount == 1 ? "" : "s")", systemImage: "bicycle")
                    Label(cell.distance.converted(to: .kilometers)
                        .formatted(.measurement(width: .abbreviated, usage: .road)),
                          systemImage: "arrow.right")
                } else {
                    Text("Rest day").foregroundStyle(.secondary)
                }
            }
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }
}



#Preview {
    HeatmapView(activities: .random(pastDaysToGenerate: 200))
}
