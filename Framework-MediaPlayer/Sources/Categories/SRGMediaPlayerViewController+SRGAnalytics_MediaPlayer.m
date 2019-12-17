//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerViewController+SRGAnalytics_MediaPlayer.h"

@implementation SRGMediaPlayerViewController (SRGAnalytics_MediaPlayer)

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return @"player";
}

@end
