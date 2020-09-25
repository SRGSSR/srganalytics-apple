//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (SRGAnalytics)

/**
 *  Return `YES` iff the application bundle corresponds to an App Store or TestFlight release.
 */
@property (class, nonatomic, readonly) BOOL srg_isProductionVersion;

@end

NS_ASSUME_NONNULL_END
