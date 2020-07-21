//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsConfiguration.h"

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Tracker for NetMetrix related events.
 */
@interface SRGAnalyticsNetMetrixTracker : NSObject

/**
 *  Create a tracker sending events for the specified configuration.
 *
 *  @param configuration The configuration to use.
 *
 *  @return The Netmetrix tracker.
 */
- (instancetype)initWithConfiguration:(SRGAnalyticsConfiguration *)configuration;

/**
 *  Send a view event.
 */
- (void)trackView;

@end

@interface SRGAnalyticsNetMetrixTracker (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
