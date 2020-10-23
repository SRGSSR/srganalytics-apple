//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsLabels.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Private category for implementation purposes.
 */
@interface SRGAnalyticsLabels (Private)

/**
 *  Dictionary containing the raw values which will be sent to TagCommander.
 */
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *labelsDictionary;

/**
 *  Dictionary containing the raw values which will be sent to comScore.
 */
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *comScoreLabelsDictionary;


@end

NS_ASSUME_NONNULL_END
