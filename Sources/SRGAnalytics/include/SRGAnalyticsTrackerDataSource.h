//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsLabels.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SRGAnalyticsTrackerDataSource <NSObject>

@property (nonatomic, readonly, copy) SRGAnalyticsLabels *srg_globalLabels;

@end

NS_ASSUME_NONNULL_END
