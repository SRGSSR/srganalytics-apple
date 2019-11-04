//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGResource+SRGAnalytics_DataProvider.h"

#import <libextobjc/libextobjc.h>

@implementation SRGResource (SRGAnalytics_DataProvider)

- (BOOL)srg_requiresDRM
{
    return self.DRMs.count != 0;
}

@end
