//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPlaybackSettings.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

// Completion block signatures.
typedef void (^SRGPlaybackContextBlock)(NSURL *streamURL, SRGResource *resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels);

@interface SRGMediaComposition (SRGAnalytics_DataProvider)

/**
 *  Retrieve a playback context for the receiver, trying to use the specified preferred settings. If no exact match can
 *  be found for the specified settings, a recommended approaching valid setup will be used instead.
 *
 *  @param preferredSettings The settings which should ideally be applied. If `nil`, default settings are used.
 *  @param resultBlock       The block called to return the resolved resource context (stream URL, resource, segments
 *                           associated with the media, segment index to start at, as well as consolidated analytics labels).
 *
 *  @return `YES` if a playback context can be resolved, in which case the context block is called. If no context can
 *          be resolved, the method returns `NO` and the context block is not called.
 *
 *  @discussion Resource lookup is performed in the order of the parameters (streaming method first, quality last).
 */
- (BOOL)playbackContextWithPreferredSettings:(nullable SRGPlaybackSettings *)preferredSettings
                                contextBlock:(NS_NOESCAPE SRGPlaybackContextBlock)contextBlock;

@end

NS_ASSUME_NONNULL_END
