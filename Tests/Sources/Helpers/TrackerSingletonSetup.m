//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>

// The singleton can be only setup once. Do not perform in a test case setup
__attribute__((constructor)) static void SetupTestSingletonTracker(void)
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       container:10
                                                                                             comScoreVirtualSite:@"rts-app-test-v"
                                                                                             netMetrixIdentifier:@"test"];
    configuration.unitTesting = YES;
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration];
    
    // The comScore SDK caches events recorded during the initial ~5 seconds after it has been initialized. Then events
    // are sent as they are recorded. For this reason, to get reliable timings in our tests, we need to wait ~5 seconds
    // after starting the tracker
    [NSThread sleepForTimeInterval:6.];
}
