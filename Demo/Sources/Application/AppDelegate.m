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
                                                                                                       sourceKey:@"source-key"
                                                                                                        siteName:@"rts-app-test-v"];
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration identityService:SRGIdentityService.currentIdentityService];
    
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

@end
