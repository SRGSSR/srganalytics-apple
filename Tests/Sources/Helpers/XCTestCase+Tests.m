//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

#import <SRGAnalytics/SRGAnalytics.h>

static __attribute__((constructor)) void AnalyticsTestCaseInit(void)
{
    NSString *contentProtectionFrameworkPath = [NSBundle.mainBundle pathForResource:@"SRGContentProtection" ofType:@"framework" inDirectory:@"Frameworks"];
    NSBundle *contentProtectionFramework = [NSBundle bundleWithPath:contentProtectionFrameworkPath];
    [contentProtectionFramework loadAndReturnError:NULL];
}

@implementation XCTestCase (Tests)

#pragma mark Helpers

- (XCTestExpectation *)expectationForSingleNotification:(NSNotificationName)notificationName object:(id)objectToObserve handler:(XCNotificationExpectationHandler)handler
{
    NSString *description = [NSString stringWithFormat:@"Expectation for notification '%@' from object %@", notificationName, objectToObserve];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:description];
    __block id observer = [NSNotificationCenter.defaultCenter addObserverForName:notificationName object:objectToObserve queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        void (^fulfill)(void) = ^{
            [expectation fulfill];
            [NSNotificationCenter.defaultCenter removeObserver:observer];
            observer = nil;
        };
        
        if (handler) {
            if (handler(notification)) {
                fulfill();
            }
        }
        else {
            fulfill();
        }
    }];
    return expectation;
}

- (XCTestExpectation *)expectationForPageViewEventNotificationWithHandler:(EventExpectationHandler)handler
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self expectationForSingleNotification:SRGAnalyticsRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return NO;
        }
        
        NSString *event = labels[@"event_id"];
        if ([event isEqualToString:@"screen"]) {
            return handler(event, labels);
        }
        else {
            return NO;
        }
    }];
}

- (XCTestExpectation *)expectationForHiddenEventNotificationWithHandler:(EventExpectationHandler)handler
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self expectationForSingleNotification:SRGAnalyticsRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return NO;
        }
        
        NSString *event = labels[@"event_id"];
        if ([event isEqualToString:@"screen"]) {
            return NO;
        }
        
        // Discard app overlap measurements
        NSString *name = labels[@"event_name"];
        if ([name isEqualToString:@"Installed Apps"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

- (XCTestExpectation *)expectationForPlayerEventNotificationWithHandler:(EventExpectationHandler)handler
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self expectationForSingleNotification:SRGAnalyticsRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return NO;
        }
        
        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_playerEvents;
        dispatch_once(&s_onceToken, ^{
            s_playerEvents = @[@"play", @"pause", @"seek", @"stop", @"eof"];
        });
        
        NSString *event = labels[@"event_id"];
        if ([s_playerEvents containsObject:event]) {
            return handler(event, labels);
        }
        else {
            return NO;
        }
    }];
}

- (XCTestExpectation *)expectationForComScoreHiddenEventNotificationWithHandler:(EventExpectationHandler)handler
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self expectationForSingleNotification:SRGAnalyticsComScoreRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return NO;
        }
        
        NSString *type = labels[@"ns_type"];
        if (! [type isEqualToString:@"hidden"]) {
            return NO;
        }
        
        // Discard heartbeats (hidden events, but entirely outside our control)
        NSString *event = labels[@"ns_st_ev"];
        if ([event isEqualToString:@"hb"]) {
            return NO;
        }
        
        // Discard app overlap measurements
        NSString *name = labels[@"srg_title"];
        if ([name isEqualToString:@"Installed Apps"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

- (XCTestExpectation *)expectationForComScorePlayerEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_playerEvents;
        dispatch_once(&s_onceToken, ^{
            s_playerEvents = @[@"play", @"pause", @"end" ];
        });
        
        if ([s_playerEvents containsObject:event]) {
            return handler(event, labels);
        }
        else {
            return NO;
        }
    }];
}

- (XCTestExpectation *)expectationForViewEventNotificationWithHandler:(EventExpectationHandler)handler
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self expectationForSingleNotification:SRGAnalyticsRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return NO;
        }
        
        NSString *event = labels[@"event_id"];
        if (! [event isEqualToString:@"screen"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

- (XCTestExpectation *)expectationForComScoreViewEventNotificationWithHandler:(EventExpectationHandler)handler
{
    NSString *expectedTestingIdentifier = SRGAnalyticsUnitTestingIdentifier();
    return [self expectationForSingleNotification:SRGAnalyticsComScoreRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        
        NSString *unitTestingIdentifier = labels[@"srg_test_id"];
        if (! [unitTestingIdentifier isEqualToString:expectedTestingIdentifier]) {
            return NO;
        }
        
        NSString *type = labels[@"ns_type"];
        if (! [type isEqualToString:@"view"]) {
            return NO;
        }
        
        // Discard start events (outside our control)
        NSString *event = labels[@"ns_ap_ev"];
        if ([event isEqualToString:@"start"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

- (XCTestExpectation *)expectationForElapsedTimeInterval:(NSTimeInterval)timeInterval withHandler:(void (^)(void))handler
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Wait for %@ seconds", @(timeInterval)]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
        handler ? handler() : nil;
    });
    return expectation;
}

@end
