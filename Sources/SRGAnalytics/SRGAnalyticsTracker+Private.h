//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGAnalyticsTracker (Private)

@property (nonatomic, nullable) SRGAnalyticsLabels *globalLabels;

@property (nonatomic) BOOL willEnterForeground;

- (void)trackTagCommanderEventWithLabels:(nullable NSDictionary<NSString *, NSString *> *)labels;

@end

NS_ASSUME_NONNULL_END
