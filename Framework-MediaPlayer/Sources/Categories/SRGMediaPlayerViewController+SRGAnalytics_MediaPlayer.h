//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Category enabling automatic view tracking for `SRGMediaPlayerViewController`. The view is tracked in a standard
 *  way not meant for customization.
 */
@interface SRGMediaPlayerViewController (SRGAnalytics_MediaPlayer) <SRGAnalyticsViewTracking>

@end

NS_ASSUME_NONNULL_END
