//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalyticsSwiftUI
import SwiftUI

@available(iOS 13, tvOS 13, *)
class SwiftUIViewController: NSObject {
    @objc static func viewController() -> UIViewController {
        return UIHostingController(rootView: SwiftUIView())
    }
}

@available(iOS 13, tvOS 13, *)
struct SwiftUIView: View {
    var body: some View {
        Button(action: { /* Nothing. Just to have something focusable on tvOS */}) {
            Text("SwiftUI demo")
        }
        .tracked(withTitle: "swift-ui", type: "detail_page")
    }
}

@available(iOS 13, tvOS 13, *)
struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
