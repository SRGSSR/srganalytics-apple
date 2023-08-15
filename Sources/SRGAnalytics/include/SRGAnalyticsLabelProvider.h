//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsLabels.h"

/**
 *  A protocol for providing analytics labels.
 */
@protocol SRGAnalyticsLabelProvider <NSObject>

/**
 *  The labels.
 */
@property (nonatomic, readonly) SRGAnalyticsLabels *labels;

@end
