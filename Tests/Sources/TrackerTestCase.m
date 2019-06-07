//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"
#import "XCTestCase+Tests.h"

typedef BOOL (^EventExpectationHandler)(NSString *event, NSDictionary *labels);

@interface TrackerTestCase : XCTestCase

@end

@implementation TrackerTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    SRGAnalyticsRenewUnitTestingIdentifier();
}

#pragma mark Tests

- (void)testHiddenEvent
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"hidden_event");
        XCTAssertEqualObjects(labels[@"event_name"], @"Hidden event");
        return YES;
    }];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testHiddenEventWithLabels
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"hidden_event");
        XCTAssertEqualObjects(labels[@"event_name"], @"Hidden event");
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

@end
