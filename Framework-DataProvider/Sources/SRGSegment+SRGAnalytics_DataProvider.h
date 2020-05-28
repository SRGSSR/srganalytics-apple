//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Standard implementation of analytics for a segment stemming from the SRG DataProvider library.
 */
@interface SRGSegment (SRGAnalytics_DataProvider) <SRGAnalyticsSegment>

/**
 *  The wall clock date at which the segment begins, `nil` if not specified.
 *
 *  @discussion Use for display purposes or comparisons with other wall-clock dates. For stream-related calculations
 *              and positioning, use `srg_markRange`.
 */
@property (nonatomic, readonly, nullable) NSDate *markInDate;

/**
 *  The wall clock date at which the segment ends, `nil` if not specified.
 *
 *  @discussion Use for display purposes or comparisons with other wall-clock dates. For stream-related calculations
 *              and positioning, use `srg_markRange`.
 */
@property (nonatomic, readonly, nullable) NSDate *markOutDate;

@end

NS_ASSUME_NONNULL_END
