//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"
#import "TrackerSingletonSetup.h"
#import "XCTestCase+Tests.h"

@import TCServerSide_noIDFA;

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

- (void)testUniqueIdentifier
{
    NSString *uniqueIdentifier = TCPredefinedVariables.sharedInstance.uniqueIdentifier;
    [self expectationForEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"context"][@"device"][@"sdk_id"], uniqueIdentifier);
        XCTAssertEqualObjects(labels[@"user"][@"consistent_anonymous_id"], uniqueIdentifier);
        return YES;
    }];

    [SRGAnalyticsTracker.sharedTracker trackEventWithName:@"Event"];

    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testCommonLabelsForEvent
{
    [self expectationForEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"app_library_version"], SRGAnalyticsMarketingVersion());
        XCTAssertEqualObjects(labels[@"navigation_app_site_name"], @"srg-test-analytics-apple");
        XCTAssertTrue(([@[@"phone", @"tvbox", @"tablet", @"desktop"] containsObject:labels[@"navigation_device"]]));
        XCTAssertEqualObjects(labels[@"consent_services"], @"service1,service2,service3");
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackEventWithName:@"Event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testCommonLabelsForPageView
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"app_library_version"], SRGAnalyticsMarketingVersion());
        XCTAssertEqualObjects(labels[@"navigation_app_site_name"], @"srg-test-analytics-apple");
        XCTAssertTrue(([@[@"phone", @"tvbox", @"tablet", @"desktop"] containsObject:labels[@"navigation_device"]]));
        XCTAssertEqualObjects(labels[@"consent_services"], @"service1,service2,service3");
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" type:@"Type" levels:nil];

    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEvent
{
    [self expectationForEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"Event");
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackEventWithName:@"Event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEventWithLabels
{
    [self expectationForEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"Event");
        XCTAssertEqualObjects(labels[@"event_type"], @"toggle");
        XCTAssertEqualObjects(labels[@"event_source"], @"favorite_list");
        XCTAssertEqualObjects(labels[@"event_value"], @"true");
        XCTAssertEqualObjects(labels[@"custom_label"], @"custom_value");
        return YES;
    }];
    
    SRGAnalyticsEventLabels *labels = [[SRGAnalyticsEventLabels alloc] init];
    labels.type = @"toggle";
    labels.source = @"favorite_list";
    labels.value = @"true";
    labels.customInfo = @{ @"custom_label" : @"custom_value" };
    [SRGAnalyticsTracker.sharedTracker trackEventWithName:@"Event"
                                                         labels:labels];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEventWithEmptyTitle
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"Events with missing title must not be sent");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [SRGAnalyticsTracker.sharedTracker trackEventWithName:@""];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testPageViewEvent
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString * event, NSDictionary * labels) {
        XCTAssertEqualObjects(event, @"page_view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_type"], @"Type"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_name"], @"Page view"); // Commanders Act SDK property
        XCTAssertNotNil(labels[@"accessed_after_push_notification"]);
        XCTAssertFalse([labels[@"accessed_after_push_notification"] boolValue]);
        XCTAssertEqualObjects(labels[@"navigation_property_type"], @"app");
        XCTAssertEqualObjects(labels[@"content_bu_owner"], @"SRG");
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" type:@"Type" levels:nil];

    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPageViewEventWithLevels
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString * event, NSDictionary * labels) {
        XCTAssertEqualObjects(event, @"page_view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_type"], @"Type"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_name"], @"Page view"); // Commanders Act SDK property
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
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" type:@"Type" levels:levels];

    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPageViewEventWithLabels
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString * event, NSDictionary * labels) {
        XCTAssertEqualObjects(event, @"page_view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_type"], @"Type"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_name"], @"Page view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"custom_label"], @"custom_value");
        return YES;
    }];
    
    SRGAnalyticsPageViewLabels *labels = [[SRGAnalyticsPageViewLabels alloc] init];
    labels.customInfo = @{ @"custom_label" : @"custom_value" };
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" type:@"Type" levels:nil labels:labels fromPushNotification:NO];

    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPageViewEventWithLevelsAndLabels
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString * event, NSDictionary * labels) {
        XCTAssertEqualObjects(event, @"page_view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_type"], @"Type"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_name"], @"Page view"); // Commanders Act SDK property
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
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" type:@"Type" levels:levels labels:labels fromPushNotification:NO];

    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPageViewEventWithEmptyTitle
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPageViewNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"Page views with missing title must not be sent");
    }];

    [self expectationForElapsedTimeInterval:5. withHandler:nil];

    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"" type:@"Type" levels:nil];

    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testPageViewEventWithEmptyType
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPageViewNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"Page views with missing type must not be sent");
    }];

    [self expectationForElapsedTimeInterval:5. withHandler:nil];

    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Title" type:@"" levels:nil];

    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testPageViewEventFromPushNotification
{
    [self expectationForPageViewEventNotificationWithHandler:^BOOL(NSString * event, NSDictionary * labels) {
        XCTAssertEqualObjects(event, @"page_view"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_type"], @"Type"); // Commanders Act SDK property
        XCTAssertEqualObjects(labels[@"page_name"], @"Page view"); // Commanders Act SDK property
        XCTAssertNotNil(labels[@"accessed_after_push_notification"]);
        XCTAssertTrue([labels[@"accessed_after_push_notification"] boolValue]);
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:@"Page view" type:@"Type" levels:nil labels:nil fromPushNotification:YES];

    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
