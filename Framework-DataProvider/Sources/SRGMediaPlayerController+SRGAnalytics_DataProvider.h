//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPlaybackSettings.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Options (as an `NSDictionary<SRGResourceLoaderOption, id>`) which can be provided to the media resource loader,
 *  through the `userInfo` dictionary supplied to playback methods.
 *
 *  @see `SRGResourceLoaderOption` for valid values.
 */
OBJC_EXPORT NSString * const SRGAnalyticsDataProviderUserInfoResourceLoaderOptionsKey;

/**
 *  Data provider compatibility additions to `SRGMediaPlayerController`. By playing medias with the methods provided
 *  by this category, playback and analytics metadata is entirely retrieved from the Integration Layer and automatically
 *  managed without additional work.
 *
 *  For more information about stream measurements, @see SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h.
 */
@interface SRGMediaPlayerController (SRGAnalytics_DataProvider)

/**
 *  Play a media composition, trying to use the specified preferred settings. If no exact match can be found for the
 *  specified settings, a recommended approaching valid setup will be used instead.
 *
 *  @param mediaComposition  The media composition to prepare.
 *  @param position          The position to start at. If `nil` or if the specified position lies outside the content
 *                           time range, playback starts at the default position.
 *  @param preferredSettings The settings which should ideally be applied. If `nil`, default settings are used.
 *  @param userInfo          Optional dictionary conveying arbitrary information during playback.
 *  @param completionHandler The completion block to be called after the player has finished preparing the media. This
 *                           block will only be called if the media could be loaded.
 *
 *  @return Returns `YES` iff playback could be started.
 *
 *  @discussion Resource lookup is performed in the order of the parameters (streaming method first, then quality last).
 */
- (BOOL)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                           atPosition:(nullable SRGPosition *)position
                withPreferredSettings:(nullable SRGPlaybackSettings *)preferredSettings
                             userInfo:(nullable NSDictionary *)userInfo
                    completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Same as `-prepareToPlayMediaComposition:atPosition:withPreferredSettings:userInfo:completionHandler:`, but automatically
 *  starting playback once the player has been prepared.
 */
- (BOOL)playMediaComposition:(SRGMediaComposition *)mediaComposition
                  atPosition:(nullable SRGPosition *)position
       withPreferredSettings:(nullable SRGPlaybackSettings *)preferredSettings
                    userInfo:(nullable NSDictionary *)userInfo;

/**
 *  The media composition currently played, if any.
 *
 *  @discussion This property can also be used to update the media composition currently being played. Only media compositions with
 *              identical main chapter will be taken into account.
 */
@property (nonatomic, nullable) SRGMediaComposition *mediaComposition;

/**
 *  The resource used for playback, `nil` if none.
 */
@property (nonatomic, readonly, nullable) SRGResource *resource;

@end

NS_ASSUME_NONNULL_END
