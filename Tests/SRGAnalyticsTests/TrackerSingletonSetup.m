//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalytics;

@interface TestDataSource : NSObject <SRGAnalyticsTrackerDataSource>

@end

@implementation TestDataSource

- (SRGAnalyticsLabels *)srg_globalLabels 
{
    SRGAnalyticsLabels *labels = [[SRGAnalyticsLabels alloc] init];
    labels.comScoreCustomInfo = @{
        @"cs_ucfr": @"1"
    };
    labels.customInfo = @{
        @"consent_services": @"service1,service2,service3"
    };
    return labels;
}

@end

static TestDataSource* dataSource(void) {
    static dispatch_once_t onceToken;
    static TestDataSource* dataSource;
    dispatch_once(&onceToken, ^{
        dataSource = [TestDataSource new];
    });
    return dataSource;
}

// The singleton can be only setup once. Do not perform in a test case setup
__attribute__((constructor)) static void SetupTestSingletonTracker(void)
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       container:10
                                                                                                        siteName:@"rts-app-test-v"];
    configuration.unitTesting = YES;
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration dataSource:dataSource()];

    // The comScore SDK caches events recorded during the initial ~5 seconds after it has been initialized. Then events
    // are sent as they are recorded. For this reason, to get reliable timings in our tests, we need to wait ~5 seconds
    // after starting the tracker
    [NSThread sleepForTimeInterval:6.];
}
