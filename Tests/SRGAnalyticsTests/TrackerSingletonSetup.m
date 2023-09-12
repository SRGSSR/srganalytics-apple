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

void SetupTestSingletonTracker(void)
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRG
                                                                                                       sourceKey:@"39ae8f94-595c-4ca4-81f7-fb7748bd3f04"
                                                                                                        siteName:@"srg-test-analytics-apple"];
    configuration.unitTesting = YES;
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration dataSource:dataSource()];

    // The comScore SDK caches events recorded during the initial ~5 seconds after it has been initialized. Then events
    // are sent as they are recorded. For this reason, to get reliable timings in our tests, we need to wait ~5 seconds
    // after starting the tracker
    [NSThread sleepForTimeInterval:6.];
}
