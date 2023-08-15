//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsLabels.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A protocol for providing analytics labels.
 */
@protocol SRGAnalyticsLabelProvider <NSObject>

/**
 *  The labels.
 */
@property (nonatomic, readonly, nullable) SRGAnalyticsLabels *labels;

@end

NS_ASSUME_NONNULL_END
