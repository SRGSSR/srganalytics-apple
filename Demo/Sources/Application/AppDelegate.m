//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "Application.h"

@import SRGAnalytics;
@import SRGAnalyticsIdentity;
@import SRGAnalyticsMediaPlayer;
@import SRGLogger;
@import TCCore;

@interface AppDelegate() <SRGAnalyticsTrackerDataSource>
@end

@implementation AppDelegate

#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    SRGIdentityService.currentIdentityService = [[SRGIdentityService alloc] initWithWebserviceURL:[NSURL URLWithString:@"https://hummingbird.rts.ch/api/profile"]
                                                                                       websiteURL:[NSURL URLWithString:@"https://www.rts.ch/profile"]];
    
    [SRGLogger setLogHandler:SRGNSLogHandler()];
    
    [TCDebug setDebugLevel:TCLogLevel_Verbose];
    [TCDebug setNotificationLog:YES];
    
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       sourceKey:@"39ae8f94-595c-4ca4-81f7-fb7748bd3f04"
                                                                                                        siteName:@"rts-app-test-v"];
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration
                                                   dataSource:self
                                              identityService:SRGIdentityService.currentIdentityService];

    if (@available(iOS 13, tvOS 13, *)) {}
    else {
        self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        [self.window makeKeyAndVisible];
        self.window.rootViewController = ApplicationRootViewController();
    }
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options API_AVAILABLE(ios(13.0))
{
    return [[UISceneConfiguration alloc] initWithName:@"Default" sessionRole:connectingSceneSession.role];
}

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
