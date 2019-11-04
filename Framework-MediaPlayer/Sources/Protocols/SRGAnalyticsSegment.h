//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsStreamLabels.h"

#import <Foundation/Foundation.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGMediaplayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol for segments conveying analytics information.
 *
 *  For more information, @see SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h.
 */
@protocol SRGAnalyticsSegment <SRGSegment>

/**
 *  Analytics labels associated with the segment.
 */
@property (nonatomic, readonly, nullable) SRGAnalyticsStreamLabels *srg_analyticsLabels;

@end

NS_ASSUME_NONNULL_END
