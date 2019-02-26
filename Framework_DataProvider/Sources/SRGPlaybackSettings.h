//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

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
 *  Set to `YES` if DRM-protected streams should be favored over non-protected ones. If set to `NO`, the first matching
 *  resource is used, based on their original order.
 *
 *  Default value is `NO`.
 */
@property (nonatomic) BOOL DRM;

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
 *  Playback source unique id.
 */
@property (nonatomic, nullable) NSString *sourceUid;

@end

NS_ASSUME_NONNULL_END
