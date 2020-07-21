//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGResource+SRGAnalyticsDataProvider.h"

@import libextobjc;

@implementation SRGResource (SRGAnalyticsDataProvider)

- (BOOL)srg_requiresDRM
{
    return self.DRMs.count != 0;
}

@end
