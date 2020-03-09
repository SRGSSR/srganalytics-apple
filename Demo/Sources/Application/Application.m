//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Application.h"

#import "DemosViewController.h"
#import "SimpleViewController.h"

UIViewController *ApplicationRootViewController(void)
{
    DemosViewController *demosViewController = [[DemosViewController alloc] init];
    UINavigationController *demosNavigationController = [[UINavigationController alloc] initWithRootViewController:demosViewController];
    demosNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Demos", nil) image:[UIImage imageNamed:@"demos"] tag:0];
    
    SimpleViewController *simpleViewController1 = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking"
                                                                                                          levels:nil
                                                                                                      customInfo:nil
                                                                                      openedFromPushNotification:NO
                                                                                            trackedAutomatically:YES];
    simpleViewController1.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Automatic tracking", nil) image:[UIImage imageNamed:@"automatic"] tag:1];
    
    SimpleViewController *simpleViewController2 = [[SimpleViewController alloc] initWithTitle:@"Manual tracking"
                                                                                       levels:nil
                                                                                   customInfo:nil
                                                                   openedFromPushNotification:NO
                                                                         trackedAutomatically:NO];
    simpleViewController2.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Manual tracking", nil) image:[UIImage imageNamed:@"manual"] tag:2];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[ demosNavigationController, simpleViewController1, simpleViewController2 ];
    
    return tabBarController;
}
