//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSegment+SRGAnalyticsDataProvider.h"

@implementation SRGSegment (SRGAnalyticsDataProvider)

#pragma mark SRGSegment protocol

- (SRGMarkRange *)srg_markRange
{
    SRGMark *markIn = self.markInDate ? [SRGMark markAtDate:self.markInDate] : [SRGMark markAtTime:CMTimeMakeWithSeconds(self.markIn / 1000., NSEC_PER_SEC)];
    SRGMark *markOut = self.markOutDate ? [SRGMark markAtDate:self.markOutDate] : [SRGMark markAtTime:CMTimeMakeWithSeconds(self.markOut / 1000., NSEC_PER_SEC)];
    return [SRGMarkRange rangeFromMark:markIn toMark:markOut];
}

- (BOOL)srg_isBlocked
{
    return [self blockingReasonAtDate:NSDate.date] != SRGBlockingReasonNone;
}

- (BOOL)srg_isHidden
{
    return self.hidden;
}

@end
