//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Application.h"

#import "DemosViewController.h"
#import "SimpleViewController.h"
#import "WebTesterViewController.h"

UIViewController *ApplicationRootViewController(void)
{
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    
    DemosViewController *demosViewController = [[DemosViewController alloc] init];
    UINavigationController *demosNavigationController = [[UINavigationController alloc] initWithRootViewController:demosViewController];
    demosNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Demos", nil) image:[UIImage imageNamed:@"demos"] tag:0];
    [viewControllers addObject:demosNavigationController];
    
    SimpleViewController *simpleViewController1 = [[SimpleViewController alloc] initWithTitle:@"Automatic tracking"
                                                                                                          levels:nil
                                                                                                      customInfo:nil
                                                                                      openedFromPushNotification:NO
                                                                                            trackedAutomatically:YES];
    simpleViewController1.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Automatic tracking", nil) image:[UIImage imageNamed:@"automatic"] tag:1];
    [viewControllers addObject:simpleViewController1];
    
    SimpleViewController *simpleViewController2 = [[SimpleViewController alloc] initWithTitle:@"Manual tracking"
                                                                                       levels:nil
                                                                                   customInfo:nil
                                                                   openedFromPushNotification:NO
                                                                         trackedAutomatically:NO];
    simpleViewController2.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Manual tracking", nil) image:[UIImage imageNamed:@"manual"] tag:2];
    [viewControllers addObject:simpleViewController2];
    
#if TARGET_OS_IOS
    WebTesterViewController *webTesterViewController = [[WebTesterViewController alloc] init];
    UINavigationController *webTesterNavigationController = [[UINavigationController alloc] initWithRootViewController:webTesterViewController];
    webTesterViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Web tester", nil) image:[UIImage imageNamed:@"web"] tag:3];
    [viewControllers addObject:webTesterNavigationController];
#endif
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = viewControllers.copy;
    
    return tabBarController;
}
