//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"
#import "TrackerSingletonSetup.h"
#import "XCTestCase+Tests.h"

@interface ComScoreTrackerTestCase : XCTestCase

@end

@implementation ComScoreTrackerTestCase

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

- (void)testNoHiddenEvents
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString *event, NSDictionary *labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

@end
