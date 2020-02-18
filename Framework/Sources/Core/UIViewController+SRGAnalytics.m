//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+SRGAnalytics.h"

#import "SRGAnalyticsTracker.h"

#import <objc/runtime.h>

// Associated object keys
static void *s_appearedOnce = &s_appearedOnce;

// Functions
static void UIViewController_SRGAnalyticsUpdateAnalyticsForWindow(UIWindow *window);

// Swizzled method original implementations
static void (*s_UIViewController_viewDidAppear)(id, SEL, BOOL);
static void (*s_UITabBarController_setSelectedViewController)(id, SEL, id);

// Swizzled method implementations
static void swizzled_UIViewController_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated);
static void swizzled_UIViewController_setSelectedViewController(UITabBarController *self, SEL _cmd, UIViewController *viewController);

@implementation UIViewController (SRGAnalytics)

#pragma mark Class methods

+ (void)load
{
    Method viewDidAppearMethod = class_getInstanceMethod(self, @selector(viewDidAppear:));
    s_UIViewController_viewDidAppear = (__typeof__(s_UIViewController_viewDidAppear))method_getImplementation(viewDidAppearMethod);
    method_setImplementation(viewDidAppearMethod, (IMP)swizzled_UIViewController_viewDidAppear);
}

#pragma mark Tracking

- (void)srg_trackPageView
{
    [self srg_trackPageViewAutomatic:NO includeContainers:NO];
}

- (void)srg_setNeedsAutomaticPageViewTrackingInChildViewController:(UIViewController *)childViewController
{
    if (! [self conformsToProtocol:@protocol(SRGAnalyticsContainerViewTracking)]) {
        return;
    }
    
    if (! [self.childViewControllers containsObject:childViewController]) {
        return;
    }
    
    [childViewController srg_trackPageViewAutomatic:YES includeContainers:YES];
}

- (void)srg_trackPageViewAutomatic:(BOOL)automatic includeContainers:(BOOL)includeContainers
{
    if (includeContainers && [self conformsToProtocol:@protocol(SRGAnalyticsContainerViewTracking)]) {
        id<SRGAnalyticsContainerViewTracking> containerSelf = (id<SRGAnalyticsContainerViewTracking>)self;
        NSArray<UIViewController *> *activeViewControllers = containerSelf.srg_activeChildViewControllers;
        for (UIViewController *viewController in activeViewControllers) {
            [viewController srg_trackPageViewAutomatic:automatic includeContainers:includeContainers];
        }
    }
    
    // Not an else-if here: The container itself could be tracked as well.
    if ([self conformsToProtocol:@protocol(SRGAnalyticsViewTracking)]) {
        id<SRGAnalyticsViewTracking> trackedSelf = (id<SRGAnalyticsViewTracking>)self;
        
        if (automatic && [trackedSelf respondsToSelector:@selector(srg_isTrackedAutomatically)] && ! [trackedSelf srg_isTrackedAutomatically]) {
            return;
        }
        
        // Inhibit container-triggered updates until the view controller has been displayed only once. First appearance
        // is detected by the view controller itself when added as a child.
        BOOL appearedOnce = [objc_getAssociatedObject(self, s_appearedOnce) boolValue];
        if (includeContainers && ! appearedOnce) {
            return;
        }
        
        NSString *title = [trackedSelf srg_pageViewTitle];
        
        NSArray<NSString *> *levels = nil;
        if ([trackedSelf respondsToSelector:@selector(srg_pageViewLevels)]) {
            levels = [trackedSelf srg_pageViewLevels];
        }
        
        SRGAnalyticsPageViewLabels *labels = nil;
        if ([trackedSelf respondsToSelector:@selector(srg_pageViewLabels)]) {
            labels = [trackedSelf srg_pageViewLabels];
        }
        
        BOOL fromPushNotification = NO;
        if ([trackedSelf respondsToSelector:@selector(srg_isOpenedFromPushNotification)]) {
            fromPushNotification = [trackedSelf srg_isOpenedFromPushNotification];
        }
        
        [SRGAnalyticsTracker.sharedTracker trackPageViewWithTitle:title
                                                           levels:levels
                                                           labels:labels
                                             fromPushNotification:fromPushNotification];
    }
}

#pragma mark Notifications

+ (void)srganalytics_sceneWillEnterForeground:(NSNotification *)notification API_AVAILABLE(ios(13.0))
{
    if ([notification.object isKindOfClass:UIWindowScene.class]) {
        UIWindowScene *windowScene = notification.object;
        [windowScene.windows enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
            UIViewController_SRGAnalyticsUpdateAnalyticsForWindow(window);
        }];
    }
}

+ (void)srganalytics_applicationWillEnterForeground:(NSNotification *)notification
{
    UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
    UIViewController_SRGAnalyticsUpdateAnalyticsForWindow(keyWindow);
}

@end

@implementation UINavigationController (SRGAnalytics)

#pragma mark SRGAnalyticsContainerViewTracking protocol

- (NSArray<UIViewController *> *)srg_activeChildViewControllers
{
    return self.topViewController ? @[self.topViewController] : @[];
}

@end

@implementation UIPageViewController (SRGAnalytics)

#pragma mark SRGAnalyticsContainerViewTracking protocol

- (NSArray<UIViewController *> *)srg_activeChildViewControllers
{
    return self.viewControllers.firstObject ? @[self.viewControllers.firstObject] : @[];
}

@end

@implementation UISplitViewController (SRGAnalytics)

- (NSArray<UIViewController *> *)srg_activeChildViewControllers
{
    return self.viewControllers;
}

@end

@implementation UITabBarController (SRGAnalytics)

#pragma mark Class methods

+ (void)load
{
    Method setSelectedViewControllerMethod = class_getInstanceMethod(self, @selector(setSelectedViewController:));
    s_UITabBarController_setSelectedViewController = (__typeof__(s_UITabBarController_setSelectedViewController))method_getImplementation(setSelectedViewControllerMethod);
    method_setImplementation(setSelectedViewControllerMethod, (IMP)swizzled_UIViewController_setSelectedViewController);
}

#pragma mark SRGAnalyticsContainerViewTracking protocol

- (NSArray<UIViewController *> *)srg_activeChildViewControllers
{
    return self.selectedViewController ? @[self.selectedViewController] : @[];
}

@end

#pragma mark Functions

__attribute__((constructor)) static void UIViewController_SRGAnalyticsInit(void)
{
    if (@available(iOS 13, *)) {
        // Scene support requires the `UIApplicationSceneManifest` key to be present in the Info.plist.
        if ([NSBundle.mainBundle objectForInfoDictionaryKey:@"UIApplicationSceneManifest"]) {
            [NSNotificationCenter.defaultCenter addObserver:UIViewController.class
                                                   selector:@selector(srganalytics_sceneWillEnterForeground:)
                                                       name:UISceneWillEnterForegroundNotification
                                                     object:nil];
        }
        else {
            [NSNotificationCenter.defaultCenter addObserver:UIViewController.class
                                                   selector:@selector(srganalytics_applicationWillEnterForeground:)
                                                       name:UIApplicationWillEnterForegroundNotification
                                                     object:nil];
        }
    }
    else {
        [NSNotificationCenter.defaultCenter addObserver:UIViewController.class
                                               selector:@selector(srganalytics_sceneWillEnterForeground:)
                                                   name:UIApplicationWillEnterForegroundNotification
                                                 object:nil];
    }
}

static void UIViewController_SRGAnalyticsUpdateAnalyticsForWindow(UIWindow *window)
{
    UIViewController *topViewController = window.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    [topViewController srg_trackPageViewAutomatic:YES includeContainers:YES];
}

static void swizzled_UIViewController_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_UIViewController_viewDidAppear(self, _cmd, animated);
    
    // Track a view controller at most once automatically when appearing. This covers all possible appearance scenarios,
    // e.g.
    //    - Moving to a parent view controller
    //    - Modal presentation
    //    - View controller revealed after having been initially hidden behind a modal view controller
    if (! [objc_getAssociatedObject(self, s_appearedOnce) boolValue]) {
        [self srg_trackPageViewAutomatic:YES includeContainers:NO];
        objc_setAssociatedObject(self, s_appearedOnce, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void swizzled_UIViewController_setSelectedViewController(UITabBarController *self, SEL _cmd, UIViewController *viewController)
{
    BOOL changed = (self.selectedViewController != viewController);
    s_UITabBarController_setSelectedViewController(self, _cmd, viewController);
    
    if (changed) {
        [self srg_setNeedsAutomaticPageViewTrackingInChildViewController:viewController];
    }
}
