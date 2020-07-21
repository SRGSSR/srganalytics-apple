//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+SRGAnalytics.h"

#import "SRGAnalyticsTracker.h"

@import UIKit;

@implementation NSBundle (SRGAnalytics)

+ (BOOL)srg_isProductionVersion
{
    // Check SIMULATOR_DEVICE_NAME for iOS 9 and above, device name below
    if ([NSProcessInfo processInfo].environment[@"SIMULATOR_DEVICE_NAME"]
            || [UIDevice.currentDevice.name.lowercaseString containsString:@"simulator"]) {
        return NO;
    }
    
    if ([NSBundle.mainBundle pathForResource:@"embedded" ofType:@"mobileprovision"]) {
        return NO;
    }
    
    return (NSBundle.mainBundle.appStoreReceiptURL != nil);
}

@end
