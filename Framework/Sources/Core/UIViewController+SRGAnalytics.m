//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+SRGAnalytics.h"

#import "SRGAnalyticsTracker.h"

#import <objc/runtime.h>

// Swizzled method original implementations
static void (*s_viewDidAppear)(id, SEL, BOOL);
static void (*s_viewWillDisappear)(id, SEL, BOOL);

// Swizzled method implementations
static void swizzled_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated);
static void swizzled_viewWillDisappear(UIViewController *self, SEL _cmd, BOOL animated);

@implementation UIViewController (SRGAnalytics)

#pragma mark Class methods

+ (void)load
{
    Method viewDidAppearMethod = class_getInstanceMethod(self, @selector(viewDidAppear:));
    s_viewDidAppear = (__typeof__(s_viewDidAppear))method_getImplementation(viewDidAppearMethod);
    method_setImplementation(viewDidAppearMethod, (IMP)swizzled_viewDidAppear);
    
    Method viewWillDisappearMethod = class_getInstanceMethod(self, @selector(viewWillDisappear:));
    s_viewWillDisappear = (__typeof__(s_viewWillDisappear))method_getImplementation(viewWillDisappearMethod);
    method_setImplementation(viewWillDisappearMethod, (IMP)swizzled_viewWillDisappear);
}

#pragma mark Tracking

- (void)srg_trackPageView
{
    return [self srg_trackPageViewForced:YES];
}

- (void)srg_trackPageViewForced:(BOOL)forced
{
    if ([self conformsToProtocol:@protocol(SRGAnalyticsViewTracking)]) {
        id<SRGAnalyticsViewTracking> trackedSelf = (id<SRGAnalyticsViewTracking>)self;
        
        if (! forced && [trackedSelf respondsToSelector:@selector(srg_isTrackedAutomatically)] && ! [trackedSelf srg_isTrackedAutomatically]) {
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
        
        [[SRGAnalyticsTracker sharedTracker] trackPageViewWithTitle:title
                                                             levels:levels
                                                             labels:labels
                                               fromPushNotification:fromPushNotification];
    }
}

#pragma mark Notifications

- (void)srg_viewController_analytics_applicationWillEnterForeground:(NSNotification *)notification
{
    [self srg_trackPageViewForced:NO];
}

@end

#pragma mark Functions

static void swizzled_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_viewDidAppear(self, _cmd, animated);
    
    if ([self isMovingToParentViewController]) {
        [self srg_trackPageViewForced:NO];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(srg_viewController_analytics_applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

static void swizzled_viewWillDisappear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_viewWillDisappear(self, _cmd, animated);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}
