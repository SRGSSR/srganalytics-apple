//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

@implementation NSNotificationCenter (Tests)

- (id<NSObject>)addObserverForHiddenEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self addObserverForName:SRGAnalyticsRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return;
        }
        
        NSString *event = labels[@"event_id"];
        if ([event isEqualToString:@"screen"]) {
            return;
        }
        
        // Discard app overlap measurements
        NSString *name = labels[@"event_name"];
        if ([name isEqualToString:@"Installed Apps"]) {
            return;
        }
        
        block(event, labels);
    }];
}

- (id<NSObject>)addObserverForPlayerEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    return [self addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_playerEvents;
        dispatch_once(&s_onceToken, ^{
            s_playerEvents = @[@"play", @"pause", @"seek", @"stop", @"eof"];
        });
        
        if ([s_playerEvents containsObject:event]) {
            block(event, labels);
        }
        else {
            return;
        }
    }];
}

- (id<NSObject>)addObserverForComScoreHiddenEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self addObserverForName:SRGAnalyticsComScoreRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return;
        }
        
        NSString *type = labels[@"ns_type"];
        if (! [type isEqualToString:@"hidden"]) {
            return;
        }
        
        // Discard heartbeats (hidden events, but entirely outside our control)
        NSString *event = labels[@"ns_st_ev"];
        if ([event isEqualToString:@"hb"]) {
            return;
        }
        
        // Discard app overlap measurements
        NSString *name = labels[@"srg_title"];
        if ([name isEqualToString:@"Installed Apps"]) {
            return;
        }
        
        block(event, labels);
    }];
}

- (id<NSObject>)addObserverForComScorePlayerEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    return [self addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_playerEvents;
        dispatch_once(&s_onceToken, ^{
            s_playerEvents = @[@"play", @"pause", @"end"];
        });
        
        if ([s_playerEvents containsObject:event]) {
            block(event, labels);
        }
        else {
            return;
        }
    }];
}

@end
