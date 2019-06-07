//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

// Key under which media player labels are stored in the media player controller user information (as
// `NSDictionary<NSString *, NSString *>`).
OBJC_EXPORT NSString * const SRGAnalyticsMediaPlayerLabelsKey;

/**
 *  Convert a `CMTime` into an amount of milliseconds.
 */
OBJC_EXPORT NSInteger SRGMediaAnalyticsCMTimeToMilliseconds(CMTime time);

/**
 *  Return `YES` iff a given stream type corresponds to a livestream.
 */
OBJC_EXPORT BOOL SRGMediaAnalyticsIsLiveStreamType(SRGMediaPlayerStreamType streamType);

/**
 *  Calculate a timeshift value in milliseconds for a stream with the specified time, time range information, current
 *  position in time, as well as a tolerance for the DVR window.
 *
 *  @discussion If the stream type played is not a livestream, the function returns `nil`.
 */
OBJC_EXPORT NSNumber * _Nullable SRGMediaAnalyticsTimeshiftInMilliseconds(SRGMediaPlayerStreamType streamType, CMTimeRange timeRange, CMTime time, NSTimeInterval liveTolerance);

/**
 *  Calculate the current timeshift value in milliseconds of the specified media player controller, in milliseconds.
 *
 *  @discussion If the stream being played is not a livestream, the function returns `nil`.
 */
OBJC_EXPORT NSNumber * _Nullable  SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(SRGMediaPlayerController *mediaPlayerController);

NS_ASSUME_NONNULL_END
