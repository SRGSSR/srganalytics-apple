//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGResource (SRGAnalytics_DataProvider)

/**
 *  Returns `YES` iff the resource requires DRM.
 */
@property (nonatomic, readonly) BOOL srg_requiresDRM;

@end

NS_ASSUME_NONNULL_END
