//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Analytics labels.
 */
@interface SRGAnalyticsLabels : NSObject <NSCopying>

/**
 *  Additional custom information, mapping variables to values.
 *
 *  You should rarely need to provide custom information with measurements, as this requires the variable name to be
 *  declared on TagCommander portal first (otherwise the associated value will be discarded).
 *
 *  Custom information can be used to override official labels. You should use this ability sparingly, though.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *customInfo;

/**
 *  Additional custom information to be sent to comScore.
 *
 *  Custom information can be used to override official labels. You should use this ability sparingly, though.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *comScoreCustomInfo;

@end

NS_ASSUME_NONNULL_END
