//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVPlayerItem+SRGAnalyticsMediaPlayer.h"

@implementation AVPlayerItem (SRGAnalyticsMediaPlayer)

- (AVMediaSelectionOption *)srganalytics_selectedMediaOptionInMediaSelectionGroup:(AVMediaSelectionGroup *)mediaSelectionGroup
{
#if TARGET_OS_TV
    AVMediaSelection *currentMediaSelection = self.currentMediaSelection;
    return [currentMediaSelection selectedMediaOptionInMediaSelectionGroup:mediaSelectionGroup];
#else
    if (@available(iOS 11, *)) {
        AVMediaSelection *currentMediaSelection = self.currentMediaSelection;
        return [currentMediaSelection selectedMediaOptionInMediaSelectionGroup:mediaSelectionGroup];
    }
    else {
        return [self selectedMediaOptionInMediaSelectionGroup:mediaSelectionGroup];
    }
#endif
}

@end
