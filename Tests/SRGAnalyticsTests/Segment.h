//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

@interface Segment : NSObject <SRGSegment>

+ (Segment *)segmentWithTimeRange:(CMTimeRange)timeRange;
+ (Segment *)blockedSegmentWithTimeRange:(CMTimeRange)timeRange;

- (instancetype)initWithTimeRange:(CMTimeRange)timeRange;

@end

NS_ASSUME_NONNULL_END
