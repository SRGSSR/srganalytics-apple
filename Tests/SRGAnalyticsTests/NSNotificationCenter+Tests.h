//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSNotificationCenter (Tests)

- (id<NSObject>)addObserverForHiddenEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block;
- (id<NSObject>)addObserverForPlayerEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block;

- (id<NSObject>)addObserverForComScoreHiddenEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block;
- (id<NSObject>)addObserverForComScorePlayerEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block;

@end

NS_ASSUME_NONNULL_END
