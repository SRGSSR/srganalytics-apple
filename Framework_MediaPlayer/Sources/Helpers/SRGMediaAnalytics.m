//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaAnalytics.h"

NSString * const SRGAnalyticsMediaPlayerLabelsKey = @"SRGAnalyticsMediaPlayerLabels";

NSInteger SRGMediaAnalyticsCMTimeToMilliseconds(CMTime time)
{
    if (CMTIME_IS_INDEFINITE(time) || CMTIME_IS_INVALID(time)) {
        return 0;
    }
    else {
        return (NSInteger)fmax(floorf(CMTimeGetSeconds(time) * 1000.), 0.);
    }
}

BOOL SRGMediaAnalyticsIsLiveStreamType(SRGMediaPlayerStreamType streamType)
{
    return streamType == SRGMediaPlayerStreamTypeLive || streamType == SRGMediaPlayerStreamTypeDVR;
}

NSNumber *SRGMediaAnalyticsTimeshiftInMilliseconds(SRGMediaPlayerStreamType streamType, CMTimeRange timeRange, CMTime time, NSTimeInterval liveTolerance)
{
    // Do not return any value for non-live streams
    if (streamType == SRGMediaPlayerStreamTypeDVR) {
        CMTime timeShift = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), time);
        NSInteger timeShiftInSeconds = (NSInteger)fabs(CMTimeGetSeconds(timeShift));
        
        // Consider offsets smaller than the tolerance to be equivalent to live conditions, sending 0 instead of the real offset
        if (timeShiftInSeconds <= liveTolerance) {
            return @0;
        }
        else {
            return @(timeShiftInSeconds * 1000);
        }
    }
    else if (streamType == SRGMediaPlayerStreamTypeLive) {
        return @0;
    }
    else {
        return nil;
    }
}

NSNumber *SRGMediaAnalyticsPlayerTimeshiftInMilliseconds(SRGMediaPlayerController *mediaPlayerController)
{
    return SRGMediaAnalyticsTimeshiftInMilliseconds(mediaPlayerController.streamType,
                                                    mediaPlayerController.timeRange,
                                                    mediaPlayerController.currentTime,
                                                    mediaPlayerController.liveTolerance);
}
