//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSMutableDictionary+SRGAnalytics.h"

@implementation NSMutableDictionary (SRGAnalytics)

- (void)srg_safelySetString:(NSString *)string forKey:(NSString *)key
{
    if (string && key) {
        [self setObject:string forKey:key];
    }
    else if (key) {
        [self removeObjectForKey:key];
    }
}

@end
