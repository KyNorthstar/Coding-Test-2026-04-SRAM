//
//  HeadmapLoadingView.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//  Portions of this file were created using Claude 4.6 Sonnet
//

import Combine
import SwiftUI



/// The hero screen — a 52-week riding heatmap with month labels and an orange intensity ramp.
///
/// Layout: a horizontal stack of [month label column | LazyVGrid]. Month label frames
/// are sized to `weekCount × rowHeight` so each label centers within its month without
/// any manual offset arithmetic. Color is computed in HSB so a single function produces
/// the full peach → amber → burnt-orange ramp without hardcoded swatches.
struct HeatmapLoadingView: View {
    
    private let client: StravaApiClient
    
    @State private var activityLoadingState: FailableLoadingState<[Activity], ActivityLoadError> = .notStarted
    
    
    init(client: StravaApiClient) {
        self.client = client
    }
    
    
    var body: some View {
        Group {
            switch activityLoadingState {
            case .notStarted,
                    .loading:
                ProgressView()
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .task {
                        activityLoadingState = .loading
                        //try? await Task.sleep(for: .seconds(0.5))
                        do {
                            activityLoadingState = .success(try await client.fetchActivities())
                        }
                        catch let error as ActivityLoadError {
                            activityLoadingState = .failure(error)
                        }
                        catch {
                            // https://github.com/swiftlang/swift/issues/87556
                            assertionFailure("Impossible error")
                        }
                    }
                
            case .success(let activities):
                HeatmapView(activities: activities)
                
            case .failure(let error):
                Text(error.localizedDescription)
            }
        }
    }
}
