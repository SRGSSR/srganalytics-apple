//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalytics;
@import SRGDataProvider;

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaComposition (SRGAnalyticsDataProvider_Private)

/**
 *  Return the consolidated analytics stream labels associated with the specified resource of the receiver.
 *
 *  @discussion An exception is thrown in debug builds if the resource is not associated with the receiver.
 */
- (SRGAnalyticsStreamLabels *)analyticsLabelsForResource:(SRGResource *)resource sourceUid:(nullable NSString *)sourceUid;

@end

NS_ASSUME_NONNULL_END
