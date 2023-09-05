//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#if canImport(Combine)  // TODO: Can be removed once iOS 11 is the minimum target declared in the package manifest. Combine is
                        //       used as testing canImport(SwiftUI) succeeds when building armv7 binaries.

import SRGAnalytics
import SwiftUI

/**
 *  A SwiftUI view for tracking page views.
 */
@available(iOS 13.0, tvOS 13.0, *)
@available(watchOS, unavailable)
struct SRGPageTrackingView: UIViewControllerRepresentable {
    let title: String
    let type: String
    let levels: [String]?
    let labels: SRGAnalyticsPageViewLabels?
    
    func makeUIViewController(context: Context) -> TrackerViewController {
        return TrackerViewController(srg_pageViewTitle: title, srg_pageViewType: type, srg_pageViewLevels: levels, srg_pageViewLabels: labels)
    }
    
    func updateUIViewController(_ uiViewController: TrackerViewController, context: Context) {
        // No update logic required
    }
    
    /**
     *  A view controller to apply the tracking rules of `SRGAnalyticsViewTracking`.
     */
    class TrackerViewController: UIViewController, SRGAnalyticsViewTracking {
        let srg_pageViewTitle: String
        let srg_pageViewType: String
        let srg_pageViewLevels: [String]?
        let srg_pageViewLabels: SRGAnalyticsPageViewLabels?
        
        init(srg_pageViewTitle: String, srg_pageViewType: String, srg_pageViewLevels: [String]?, srg_pageViewLabels: SRGAnalyticsPageViewLabels?) {
            self.srg_pageViewTitle = srg_pageViewTitle
            self.srg_pageViewType = srg_pageViewType
            self.srg_pageViewLevels = srg_pageViewLevels
            self.srg_pageViewLabels = srg_pageViewLabels
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            self.srg_pageViewTitle = ""
            self.srg_pageViewType = ""
            self.srg_pageViewLevels = nil
            self.srg_pageViewLabels = nil
            super.init(coder: coder)
        }
    }
}

@available(iOS 13.0, tvOS 13.0, *)
@available(watchOS, unavailable)
public extension View {
    /**
     *  Mark a view as being tracked with the provided title, type, levels and labels.
     */
    func tracked(withTitle title: String, type: String, levels: [String]? = nil, labels: SRGAnalyticsPageViewLabels? = nil) -> some View {
        ZStack {
            SRGPageTrackingView(title: title, type: type, levels: levels, labels: labels)
            self
        }
    }
}

#endif
