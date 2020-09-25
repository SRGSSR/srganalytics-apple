//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalyticsMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

@interface Segment : NSObject <SRGAnalyticsSegment>

+ (Segment *)segmentWithName:(NSString *)name timeRange:(CMTimeRange)timeRange;
+ (Segment *)blockedSegmentWithName:(NSString *)name timeRange:(CMTimeRange)timeRange;

- (instancetype)initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange;

@property (nonatomic, readonly, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
