//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSString+SRGAnalytics.h"

@implementation NSString (SRGAnalytics)

- (NSString *)srg_comScoreFormattedString
{
    // Remove accentuated characters
    NSLocale *posixLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    NSString *normalizedString = [self.lowercaseString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:posixLocale];
    
    // See rules at https://srfmmz.atlassian.net/wiki/display/SRGPLAY/Measurement+of+SRG+Player+Apps
    NSCharacterSet *andSet = [NSCharacterSet characterSetWithCharactersInString:@"+&"];
    normalizedString = [[normalizedString componentsSeparatedByCharactersInSet:andSet] componentsJoinedByString:@"and"];
    
    // Squash all non-alphanumeric characters as a single hyphen
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"[^a-z0-9]+" options:0 error:NULL];
    normalizedString = [regularExpression stringByReplacingMatchesInString:normalizedString options:0 range:NSMakeRange(0, normalizedString.length) withTemplate:@"-"];
    
    // Trim hyphens at both ends, if any
    return [normalizedString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
}

@end
