//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (SRGAnalytics)

/**
 *  The analytics resource bundle.
 */
+ (NSBundle *)srg_analyticsBundle;

/**
 *  Return `YES` iff the application bundle corresponds to an AppStore or TestFlight release.
 */
+ (BOOL)srg_isProductionVersion;

@end

NS_ASSUME_NONNULL_END
