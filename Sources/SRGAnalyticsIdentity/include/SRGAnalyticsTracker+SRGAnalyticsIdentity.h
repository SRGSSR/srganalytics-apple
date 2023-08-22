//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalytics;
@import SRGIdentity;

NS_ASSUME_NONNULL_BEGIN

@interface SRGAnalyticsTracker (SRGAnalyticsIdentity)

/**
 *  Start the tracker. Same as `-startWithConfiguration:` SRGAnalyticsTracker method, with an optional identity service.
 *
 *  @param configuration   The configuration to use. This configuration is copied and cannot be changed afterwards.
 *  @param dataSource      The data source for the global labels.
 *  @param identityService The service which identities can be retrieved from.
 */
- (void)startWithConfiguration:(SRGAnalyticsConfiguration *)configuration
                    dataSource:(nullable id<SRGAnalyticsTrackerDataSource>)dataSource
               identityService:(nullable SRGIdentityService *)identityService;

/**
 *  The identity service associated with the tracker, if any.
 */
@property (nonatomic, readonly, nullable) SRGIdentityService *identityService;

@end

NS_ASSUME_NONNULL_END
