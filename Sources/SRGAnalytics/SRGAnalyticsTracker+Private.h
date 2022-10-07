//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGAnalyticsTracker (Private)

@property (nonatomic, nullable) SRGAnalyticsLabels *globalLabels;

- (void)trackPageViewWithTitle:(NSString *)title
                        levels:(nullable NSArray<NSString *> *)levels
                        labels:(nullable SRGAnalyticsPageViewLabels *)labels
          fromPushNotification:(BOOL)fromPushNotification
        ignoreApplicationState:(BOOL)ignoreApplicationState;

- (void)sendCommandersActCustomEventWithName:(NSString *)name
                                      labels:(nullable NSDictionary<NSString *, NSString *> *)labels;

@end

NS_ASSUME_NONNULL_END
