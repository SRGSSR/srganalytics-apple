//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"
#import "XCTestCase+Tests.h"

typedef BOOL (^EventExpectationHandler)(NSString *event, NSDictionary *labels);

@interface ComScoreTrackerTestCase : XCTestCase

@end

@implementation ComScoreTrackerTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    SRGAnalyticsRenewUnitTestingIdentifier();
}

#pragma mark Tests

- (void)testHiddenEvent
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertNil(event);
        XCTAssertEqualObjects(labels[@"srg_title"], @"Hidden event");
        XCTAssertEqualObjects(labels[@"name"], @"app.hidden-event");
        XCTAssertEqualObjects(labels[@"ns_category"], @"app");
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventWithLabels
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertNil(event);
        XCTAssertEqualObjects(labels[@"srg_title"], @"Hidden event");
        XCTAssertEqualObjects(labels[@"name"], @"app.hidden-event");
        XCTAssertEqualObjects(labels[@"ns_category"], @"app");
        XCTAssertEqualObjects(labels[@"srg_evgroup"], @"toggle");
        XCTAssertEqualObjects(labels[@"srg_evsource"], @"favorite_list");
        XCTAssertEqualObjects(labels[@"srg_evvalue"], @"true");
        XCTAssertEqualObjects(labels[@"custom_label"], @"custom_value");
        return YES;
    }];
    
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.type = @"toggle";
    labels.source = @"favorite_list";
    labels.value = @"true";
    labels.comScoreCustomInfo = @{ @"custom_label" : @"custom_value" };
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event" labels:labels];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventWithEmptyTitle
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"Events with missing title must not be sent");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@""];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

@end
