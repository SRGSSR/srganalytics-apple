//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"

@import SRGAnalyticsMediaPlayer;

@implementation NSNotificationCenter (Tests)

- (id<NSObject>)addObserverForEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self addObserverForName:SRGAnalyticsRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return;
        }
        
        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_nonEvents;
        dispatch_once(&s_onceToken, ^{
            s_nonEvents = @[@"play", @"pause", @"seek", @"stop", @"eof", @"segment", @"pos", @"uptime", @"page_view"];
        });
        
        NSString *event = labels[@"event_name"];
        if ([s_nonEvents containsObject:event]) {
            return;
        }
        
        block(event, labels);
    }];
}

- (id<NSObject>)addObserverForPageViewNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self addObserverForName:SRGAnalyticsRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];

        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return;
        }

        NSString *event = labels[@"event_name"];
        if (! [event isEqualToString:@"page_view"]) {
            return;
        }

        block(event, labels);
    }];
}

- (id<NSObject>)addObserverForPlayerEventNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self addObserverForName:SRGAnalyticsRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return;
        }

        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_playerEvents;
        dispatch_once(&s_onceToken, ^{
            s_playerEvents = @[@"play", @"pause", @"seek", @"stop", @"eof", @"segment"];
        });

        NSString *event = labels[@"event_name"];
        if (! [s_playerEvents containsObject:event]) {
            return;
        }

        block(event, labels);
    }];
}

- (id<NSObject>)addObserverForPlayerHeartbeatNotificationUsingBlock:(void (^)(NSString *event, NSDictionary *labels))block
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self addObserverForName:SRGAnalyticsRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return;
        }

        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_heartbeatEvents;
        dispatch_once(&s_onceToken, ^{
            s_heartbeatEvents = @[@"pos", @"uptime"];
        });

        NSString *event = labels[@"event_name"];
        if (! [s_heartbeatEvents containsObject:event]) {
            return;
        }

        block(event, labels);
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
        
        if (! [s_playerEvents containsObject:event]) {
            return;
        }

        block(event, labels);
    }];
}

@end
