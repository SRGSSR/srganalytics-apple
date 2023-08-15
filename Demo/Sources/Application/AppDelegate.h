//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalytics;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : UIResponder <UIApplicationDelegate, SRGAnalyticsLabelProvider>

// TODO: Remove when SRG Analytics demo requires iOS 13
@property (nonatomic) UIWindow *window;

@end

NS_ASSUME_NONNULL_END
