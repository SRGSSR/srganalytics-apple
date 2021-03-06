//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

/**
 *  The default start bit rate.
 */
static const NSUInteger SRGDefaultStartBitRate = 800;

/**
 *  Settings to be applied when performing resource lookup retrieval for media playback. Resource lookup attempts
 *  to find a close match for a set of settings.
 */
@interface SRGPlaybackSettings : NSObject <NSCopying>

/**
 *  The streaming method to use. Default value is `SRGStreamingMethodNone`.
 *
 *  @discussion If `SRGStreamingMethodNone` or if no matching resource is found during resource lookup, a recommended
 *              method is used instead.
 */
@property (nonatomic) SRGStreamingMethod streamingMethod;

/**
 *  The stream type to use. Default value is `SRGStreamTypeNone`.
 *
 *  @discussion If `SRGStreamTypeNone` or if no matching resource is found during resource lookup, a recommended
 *              method is used instead.
 */
@property (nonatomic) SRGStreamType streamType;

/**
 *  The quality to use. Default value is `SRGQualityNone`.
 *
 *  @discussion If `SRGQualityNone` or if no matching resource is found during resource lookup, the best available
 *              quality is used instead.
 */
@property (nonatomic) SRGQuality quality;

/**
 *  The bit rate the media should start playing with, in kbps. This parameter is a recommendation with no result guarantee,
 *  though it should in general be applied. The nearest available quality (larger or smaller than the requested size) is
 *  used.
 *
 *  Usual SRG SSR valid bit ranges vary from 100 to 3000 kbps. Use 0 to start with the lowest quality stream.
 *
 *  Default value is `SRGDefaultStartBitRate`.
 */
@property (nonatomic) NSUInteger startBitRate;

/**
 *  A source unique identifier to be associated with the playback. This can be used to convey information about where
 *  the media was retrieved from (e.g. a media list identifier).
 */
@property (nonatomic, nullable, copy) NSString *sourceUid;

@end

NS_ASSUME_NONNULL_END
