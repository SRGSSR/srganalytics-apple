//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSegment+SRGAnalytics_DataProvider.h"

#import <objc/runtime.h>

// Associated object keys
static void *s_resourceReferenceDate = &s_resourceReferenceDate;
static void *s_streamOffset = &s_streamOffset;

@interface SRGSegment (SRGAnalytics_DataProvider_Private)

@property (nonatomic) NSDate *resourceReferenceDate;
@property (nonatomic) NSTimeInterval streamOffset;

@end

@implementation SRGSegment (SRGAnalytics_DataProvider)

#pragma mark Getters and setters

- (NSDate *)resourceReferenceDate
{
    return objc_getAssociatedObject(self, s_resourceReferenceDate);
}

- (void)setResourceReferenceDate:(NSDate *)resourceReferenceDate
{
    objc_setAssociatedObject(self, s_resourceReferenceDate, resourceReferenceDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)streamOffset
{
    return [objc_getAssociatedObject(self, s_streamOffset) doubleValue];
}

- (void)setStreamOffset:(NSTimeInterval)streamOffset
{
    objc_setAssociatedObject(self, s_streamOffset, @(streamOffset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// TODO: Once streamOffset is not required anymore, update the documentation of these properties (will be used
//       interchangeably with the mark range).

- (NSDate *)markInDate
{
    if (self.resourceReferenceDate) {
        return [self.resourceReferenceDate dateByAddingTimeInterval:self.markIn / 1000.];
    }
    else {
        return nil;
    }
}

- (NSDate *)markOutDate
{
    if (self.resourceReferenceDate) {
        return [self.resourceReferenceDate dateByAddingTimeInterval:self.markOut / 1000.];
    }
    else {
        return nil;
    }
}

#pragma mark SRGAnalyticsSegment protocol

- (SRGMarkRange *)srg_markRange
{
    if (self.resourceReferenceDate) {
        NSDate *markInDate = [self.resourceReferenceDate dateByAddingTimeInterval:(self.markIn + self.streamOffset) / 1000.];
        NSDate *markOutDate = [self.resourceReferenceDate dateByAddingTimeInterval:(self.markOut + self.streamOffset) / 1000.];
        return [SRGMarkRange rangeFromMark:[SRGMark markAtDate:markInDate] toMark:[SRGMark markAtDate:markOutDate]];
    }
    else {
        SRGMark *fromMark = [SRGMark markAtTime:CMTimeMakeWithSeconds(self.markIn / 1000., NSEC_PER_SEC)];
        SRGMark *toMark = [SRGMark markAtTime:CMTimeMakeWithSeconds(self.markOut / 1000., NSEC_PER_SEC)];
        return [SRGMarkRange rangeFromMark:fromMark toMark:toMark];
    }
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

void SRGAnalyticsDataProviderAssociateSegmentDateInformation(NSArray<SRGSegment *> *segments, NSDate *resourceReferenceDate, NSTimeInterval streamOffset)
{
    [segments enumerateObjectsUsingBlock:^(SRGSegment * _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
        segment.resourceReferenceDate = resourceReferenceDate;
        segment.streamOffset = streamOffset;
    }];
}
