//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPlaybackSettings.h"

@implementation SRGPlaybackSettings

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.streamingMethod = SRGStreamingMethodNone;
        self.streamType = SRGStreamTypeNone;
        self.quality = SRGQualityNone;
    }
    return self;
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    SRGPlaybackSettings *settings = [self.class allocWithZone:zone];
    settings.streamingMethod = self.streamingMethod;
    settings.streamType = self.streamType;
    settings.quality = self.quality;
    settings.sourceUid = self.sourceUid;
    return settings;
}

@end
