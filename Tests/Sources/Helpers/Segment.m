//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

@interface Segment ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic) SRGMarkRange *srg_markRange;
@property (nonatomic, getter=srg_isBlocked) BOOL srg_blocked;

@end

@implementation Segment

#pragma mark Class methods

+ (Segment *)segmentWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    return [[self.class alloc] initWithName:name timeRange:timeRange];
}

+ (Segment *)blockedSegmentWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    Segment *segment = [[self.class alloc] initWithName:name timeRange:timeRange];
    segment.srg_blocked = YES;
    return segment;
}

#pragma mark Object lifecycle

- (instancetype)initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    if (self = [super init]) {
        self.name = name;
        self.srg_markRange = [SRGMarkRange rangeFromTimeRange:timeRange];
    }
    return self;
}

#pragma mark Getters and setters

- (BOOL)srg_isHidden
{
    // NO need to test hidden segments in unit tests, those are only for use by UI overlays
    return NO;
}

#pragma mark SRGAnalyticsSegment protocol

- (SRGAnalyticsStreamLabels *)srg_analyticsLabels
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.customInfo = @{ @"segment_name" : self.name,
                           @"overridable_name" : self.name };
    labels.comScoreCustomInfo = @{ @"segment_name" : self.name,
                                   @"overridable_name" : self.name };
    return labels;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; name = %@; range = %@>",
            self.class,
            self,
            self.name,
            self.srg_markRange];
}

@end
