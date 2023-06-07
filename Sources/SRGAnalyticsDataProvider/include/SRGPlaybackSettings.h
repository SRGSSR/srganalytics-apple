//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

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
 *  A source unique identifier to be associated with the playback. This can be used to convey information about where
 *  the media was retrieved from (e.g. a media list identifier).
 */
@property (nonatomic, nullable, copy) NSString *sourceUid;

@end

NS_ASSUME_NONNULL_END
