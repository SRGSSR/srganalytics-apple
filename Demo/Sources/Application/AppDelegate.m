//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "DemosViewController.h"
#import "SimpleViewController.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAnalytics_Identity/SRGAnalytics_Identity.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <SRGLogger/SRGLogger.h>
#import <TCCore/TCCore.h>

@implementation AppDelegate

#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.window makeKeyAndVisible];
    
    SRGIdentityService.currentIdentityService = [[SRGIdentityService alloc] initWithWebserviceURL:[NSURL URLWithString:@"https://hummingbird.rts.ch/api/profile"]
                                                                                       websiteURL:[NSURL URLWithString:@"https://www.rts.ch/profile"]];
    
    [SRGLogger setLogHandler:SRGNSLogHandler()];
    
    [TCDebug setDebugLevel:TCLogLevel_Verbose];
    [TCDebug setNotificationLog:YES];
    
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       container:10
                                                                                             comScoreVirtualSite:@"rts-app-test-v"
                                                                                             netMetrixIdentifier:@"test"];
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration identityService:SRGIdentityService.currentIdentityService];
    
    DemosViewController *demosViewController = [[DemosViewController alloc] init];
    UINavigationController *demosNavigationController = [[UINavigationController alloc] initWithRootViewController:demosViewController];
    
    SimpleViewController *simpleViewController1 = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking"
                                                                                                          levels:nil
                                                                                                      customInfo:nil
                                                                                      openedFromPushNotification:NO
                                                                                            trackedAutomatically:YES];
    SimpleViewController *simpleViewController2 = [[SimpleViewController alloc] initWithTitle:@"Manual tracking"
                                                                                       levels:nil
                                                                                   customInfo:nil
                                                                   openedFromPushNotification:NO
                                                                         trackedAutomatically:NO];
    
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[ demosNavigationController, simpleViewController1, simpleViewController2 ];
    
    self.window.rootViewController = tabBarController;
    
    return YES;
}

@end
