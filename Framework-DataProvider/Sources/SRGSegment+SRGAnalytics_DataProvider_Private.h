//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Consolidate information available for segment date calculations.
 */
OBJC_EXPORT void SRGAnalyticsDataProviderAssociateSegmentDateInformation(NSArray<SRGSegment *> *segments, NSDate * _Nullable resourceReferenceDate, NSTimeInterval streamOffset);

NS_ASSUME_NONNULL_END
