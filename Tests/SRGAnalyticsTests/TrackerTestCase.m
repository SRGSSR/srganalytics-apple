//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"
#import "TrackerSingletonSetup.h"
#import "XCTestCase+Tests.h"

@interface TrackerTestCase : XCTestCase

@end

@implementation TrackerTestCase

#pragma mark Setup and teardown

+ (void)setUp
{
    SetupTestSingletonTracker();
}

- (void)setUp
{
    SRGAnalyticsRenewUnitTestingIdentifier();
}

#pragma mark Tests

- (void)testNoHiddenAdSupportFramework
{
    XCTAssertNil(NSClassFromString(@"ASIdentifierManager"));
}

- (void)testCommonLabels
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"navigation_app_site_name"], @"rts-app-test-v");
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEvent
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"Hidden event");
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventWithLabels
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"Hidden event");
        XCTAssertEqualObjects(labels[@"event_type"], @"toggle");
        XCTAssertEqualObjects(labels[@"event_source"], @"favorite_list");
        XCTAssertEqualObjects(labels[@"event_value"], @"true");
        XCTAssertEqualObjects(labels[@"custom_label"], @"custom_value");
        return YES;
    }];
    
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.type = @"toggle";
    labels.source = @"favorite_list";
    labels.value = @"true";
    labels.customInfo = @{ @"custom_label" : @"custom_value" };
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"
                                                         labels:labels];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventWithEmptyTitle
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"Events with missing title must not be sent");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@""];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testPageViewEvent
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString * event, NSDictionary * labels) {
        XCTAssertEqualObjects(event, @"page_view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_type"], @"Page view"); // Commanders Act SDK property
        XCTAssertNotNil(labels[@"accessed_after_push_notification"]);
        XCTAssertFalse([labels[@"accessed_after_push_notification"] boolValue]);
        XCTAssertEqualObjects(labels[@"navigation_property_type"], @"app");
        XCTAssertEqualObjects(labels[@"navigation_bu_distributer"], @"RTS");
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" levels:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPageViewEventWithLevels
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString * event, NSDictionary * labels) {
        XCTAssertEqualObjects(event, @"page_view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_type"], @"Page view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"navigation_level_1"], @"level 1");
        XCTAssertEqualObjects(labels[@"navigation_level_2"], @"level 2");
        XCTAssertEqualObjects(labels[@"navigation_level_3"], @"level 3");
        XCTAssertEqualObjects(labels[@"navigation_level_4"], @"level 4");
        XCTAssertEqualObjects(labels[@"navigation_level_5"], @"level 5");
        XCTAssertEqualObjects(labels[@"navigation_level_6"], @"level 6");
        XCTAssertEqualObjects(labels[@"navigation_level_7"], @"level 7");
        XCTAssertEqualObjects(labels[@"navigation_level_8"], @"level 8");
        XCTAssertNil(labels[@"navigation_level_9"]);
        return YES;
    }];
    
    NSArray<NSString *> *levels = @[ @"level 1", @"level 2", @"level 3", @"level 4", @"level 5", @"level 6", @"level 7", @"level 8", @"level 9" ];
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" levels:levels];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPageViewEventWithLabels
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString * event, NSDictionary * labels) {
        XCTAssertEqualObjects(event, @"page_view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_type"], @"Page view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"custom_label"], @"custom_value");
        return YES;
    }];
    
    SRGAnalyticsPageViewLabels *labels = [[SRGAnalyticsPageViewLabels alloc] init];
    labels.customInfo = @{ @"custom_label" : @"custom_value" };
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" levels:nil labels:labels fromPushNotification:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPageViewEventWithLevelsAndLabels
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString * event, NSDictionary * labels) {
        XCTAssertEqualObjects(event, @"page_view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_type"], @"Page view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"navigation_level_1"], @"level 1");
        XCTAssertEqualObjects(labels[@"navigation_level_2"], @"level 2");
        XCTAssertEqualObjects(labels[@"navigation_level_3"], @"level 3");
        XCTAssertEqualObjects(labels[@"navigation_level_4"], @"level 4");
        XCTAssertEqualObjects(labels[@"navigation_level_5"], @"level 5");
        XCTAssertEqualObjects(labels[@"navigation_level_6"], @"level 6");
        XCTAssertEqualObjects(labels[@"navigation_level_7"], @"level 7");
        XCTAssertEqualObjects(labels[@"navigation_level_8"], @"level 8");
        XCTAssertNil(labels[@"navigation_level_9"]);
        XCTAssertEqualObjects(labels[@"custom_label"], @"custom_value");
        return YES;
    }];
    
    NSArray<NSString *> *levels = @[ @"level 1", @"level 2", @"level 3", @"level 4", @"level 5", @"level 6", @"level 7", @"level 8", @"level 9" ];
    
    SRGAnalyticsPageViewLabels *labels = [[SRGAnalyticsPageViewLabels alloc] init];
    labels.customInfo = @{ @"custom_label" : @"custom_value" };
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" levels:levels labels:labels fromPushNotification:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPageViewEventFromPushNotification
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString * event, NSDictionary * labels) {
        XCTAssertEqualObjects(event, @"page_view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_type"], @"Page view"); // Commanders Act SDK property
        XCTAssertNotNil(labels[@"accessed_after_push_notification"]);
        XCTAssertTrue([labels[@"accessed_after_push_notification"] boolValue]);
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" levels:nil labels:nil fromPushNotification:YES];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
