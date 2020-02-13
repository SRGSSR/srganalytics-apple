//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+SRGAnalytics.h"

#import "SRGAnalyticsTracker.h"

#import <libextobjc/libextobjc.h>
#import <objc/runtime.h>

// Associated object keys
static void *s_observerKey = &s_observerKey;
static void *s_appearedOnce = &s_appearedOnce;

// Swizzled method original implementations
static void (*s_UIViewController_viewDidAppear)(id, SEL, BOOL);
static void (*s_UIViewController_viewWillDisappear)(id, SEL, BOOL);
static void (*s_UITabBarController_setSelectedViewController)(id, SEL, id);

// Swizzled method implementations
static void swizzled_UIViewController_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated);
static void swizzled_UIViewController_viewWillDisappear(UIViewController *self, SEL _cmd, BOOL animated);
static void swizzled_UIViewController_setSelectedViewController(UITabBarController *self, SEL _cmd, UIViewController *viewController);

@implementation UIViewController (SRGAnalytics)

#pragma mark Class methods

+ (void)load
{
    Method viewDidAppearMethod = class_getInstanceMethod(self, @selector(viewDidAppear:));
    s_UIViewController_viewDidAppear = (__typeof__(s_UIViewController_viewDidAppear))method_getImplementation(viewDidAppearMethod);
    method_setImplementation(viewDidAppearMethod, (IMP)swizzled_UIViewController_viewDidAppear);
    
    Method viewWillDisappearMethod = class_getInstanceMethod(self, @selector(viewWillDisappear:));
    s_UIViewController_viewWillDisappear = (__typeof__(s_UIViewController_viewWillDisappear))method_getImplementation(viewWillDisappearMethod);
    method_setImplementation(viewWillDisappearMethod, (IMP)swizzled_UIViewController_viewWillDisappear);
}

#pragma mark Tracking

- (void)srg_trackPageView
{
    [self srg_trackPageViewAutomatically:NO fromContainerUpdate:NO];
}

- (void)srg_setActiveViewControllersNeedUpdate
{
    [self srg_trackPageViewAutomatically:YES fromContainerUpdate:YES];
}

- (void)srg_trackPageViewAutomatically:(BOOL)automatically fromContainerUpdate:(BOOL)fromContainerUpdate
{
    if ([self conformsToProtocol:@protocol(SRGAnalyticsContainerViewTracking)]) {
        id<SRGAnalyticsContainerViewTracking> containerSelf = (id<SRGAnalyticsContainerViewTracking>)self;
        NSArray<UIViewController *> *activeViewControllers = containerSelf.srg_activeViewControllers;
        for (UIViewController *viewController in activeViewControllers) {
            [viewController srg_trackPageViewAutomatically:automatically fromContainerUpdate:fromContainerUpdate];
        }
    }
    
    // Not an else-if here: The container itself could be tracked as well.
    if ([self conformsToProtocol:@protocol(SRGAnalyticsViewTracking)]) {
        id<SRGAnalyticsViewTracking> trackedSelf = (id<SRGAnalyticsViewTracking>)self;
        
        if (automatically && [trackedSelf respondsToSelector:@selector(srg_isTrackedAutomatically)] && ! [trackedSelf srg_isTrackedAutomatically]) {
            return;
        }
        
        // Inhibit container-triggered updates until the view controller has been displayed only once. First appearance
        // is detected by the view controller itself when added as a child.
        BOOL appearedOnce = [objc_getAssociatedObject(self, s_appearedOnce) boolValue];
        if (fromContainerUpdate && ! appearedOnce) {
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

@end

@implementation UINavigationController (SRGAnalytics)

#pragma mark SRGAnalyticsContainerViewTracking protocol

- (NSArray<UIViewController *> *)srg_activeViewControllers
{
    return @[self.topViewController];
}

@end

@implementation UIPageViewController (SRGAnalytics)

#pragma mark SRGAnalyticsContainerViewTracking protocol

- (NSArray<UIViewController *> *)srg_activeViewControllers
{
    return @[self.viewControllers.firstObject];
}

@end

@implementation UISplitViewController (SRGAnalytics)

- (NSArray<UIViewController *> *)srg_activeViewControllers
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

- (NSArray<UIViewController *> *)srg_activeViewControllers
{
    return @[self.selectedViewController];
}

@end

#pragma mark Functions

static void swizzled_UIViewController_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_UIViewController_viewDidAppear(self, _cmd, animated);
    
    // Track a view controller at most once automatically when appearing. This covers all possible appearance scenarios,
    // e.g.
    //    - Moving to a parent view controller
    //    - Modal presentation
    //    - View controller revealed after having been initially hidden behind a modal view controller
    if (! [objc_getAssociatedObject(self, s_appearedOnce) boolValue]) {
        [self srg_trackPageViewAutomatically:YES fromContainerUpdate:NO];
        objc_setAssociatedObject(self, s_appearedOnce, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    // An anonymous observer (conveniently created with the notification center registration method taking a block as
    // parameter) is required. If we simply registered `self` as observer, removal in `-viewWillDisappear:` would also
    // remove all other registrations of the view controller for the same notifications!
    @weakify(self)
    id observer = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        @strongify(self)
        [self srg_trackPageViewAutomatically:YES fromContainerUpdate:NO];
    }];
    objc_setAssociatedObject(self, s_observerKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void swizzled_UIViewController_viewWillDisappear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_UIViewController_viewWillDisappear(self, _cmd, animated);
    
    id observer = objc_getAssociatedObject(self, s_observerKey);
    [NSNotificationCenter.defaultCenter removeObserver:observer];
    objc_setAssociatedObject(self, s_observerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void swizzled_UIViewController_setSelectedViewController(UITabBarController *self, SEL _cmd, UIViewController *viewController)
{
    BOOL changed = (self.selectedViewController != viewController);
    s_UITabBarController_setSelectedViewController(self, _cmd, viewController);
    
    if (changed) {
        [self srg_setActiveViewControllersNeedUpdate];
    }
}
