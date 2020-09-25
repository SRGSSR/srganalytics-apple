//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerViewController+SRGAnalyticsMediaPlayer.h"

@implementation SRGMediaPlayerViewController (SRGAnalyticsMediaPlayer)

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return @"player";
}

@end
