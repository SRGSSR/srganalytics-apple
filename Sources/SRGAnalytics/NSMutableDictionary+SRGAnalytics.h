//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (SRGAnalytics)

/**
 *  Set string and key iff both are non-`nil`.
 */
- (void)srg_safelySetString:(nullable NSString *)string forKey:(nullable NSString *)key;

@end

NS_ASSUME_NONNULL_END
