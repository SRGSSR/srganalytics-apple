//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSegment+SRGAnalytics_DataProvider.h"

@implementation SRGSegment (SRGAnalytics_DataProvider)

#pragma mark SRGAnalyticsSegment protocol

- (CMTimeRange)srg_timeRange
{
    return CMTimeRangeMake(CMTimeMakeWithSeconds(self.markIn / 1000., NSEC_PER_SEC),
                           CMTimeMakeWithSeconds(self.duration / 1000., NSEC_PER_SEC));
}

- (BOOL)srg_isBlocked
{
    return [self blockingReasonAtDate:NSDate.date] != SRGBlockingReasonNone;
}

- (BOOL)srg_isHidden
{
    return self.hidden;
}

- (SRGAnalyticsStreamLabels *)srg_analyticsLabels
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = self.analyticsLabels;
    return labels;
}

@end
