//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  View controllers whose usage must be tracked should conform to the `SRGAnalyticsViewTracking` protocol, which
 *  describes the data to send with such events. The only method required by this protocol is `-srg_pageViewTitle`,
 *  which provides the name to be used for the view events.
 *
 *  By default, if a view controller conforms to the `SRGAnalyticsViewTracking` protocol, a page view event will
 *  automatically be sent when it is presented for the first time (i.e. when `-viewDidAppear:` is called for
 *  the first time). In addition, automatic page views are sent when the application returns from background.
 *
 *  If you need to precisely control when page view events are sent, however, you can implement the optional
 *  `-srg_isTrackedAutomatically` method to return `NO`, disabling the mechanisms described above. This is mostly
 *  useful when page view information is not available at the time `-viewDidAppear:` is called, e.g. if this
 *  information is retrieved from a web service request. Beware that in this case you are responsible of calling
 *  `-[UIViewController trackPageView]` when:
 *    - Your application is active and you received the information you needed for the page view.
 *    - Your application returns from background and the information you need for the page view is readily available.
 *
 *  If you prefer, you can also perform manual page view tracking using the corresponding methods available from
 *  `SRGAnalyticsTracker`. The same rules apply.
 *
 *  If your application uses custom view controller containers, and if you want to use automatic tracking, be sure to
 *  have them conform to the `SRGAnalyticsContainerViewTracking` protocol so that automatic page views are correctly
 *  propagated through your application view controller hierarchy. If a view controller does not implement this protocol
 *  but contains children, page view events will be propagated to all children.
 */
@protocol SRGAnalyticsViewTracking <NSObject>

/**
 *  The page view title to use for view event measurement.
 *
 *  @return The page view title. If this value is empty, no event will be sent.
 */
@property (nonatomic, readonly, copy) NSString *srg_pageViewTitle;

@optional

/**
 *  By default any view controller conforming `SRGAnalyticsViewTracking` is automatically tracked. You can disable
 *  this behavior by implementing the following method and return `NO`. In such cases, you are responsible of calling
 *  the `-[UIViewController trackPageView]` method manually when a view event must be recorded.
 *
 *  @return `YES` iff automatic tracking must be enabled, `NO` otherwise.
 *
 *  @discussion Automatic apparition tracking is considered only the first time a view controller is displayed. If
 *              the value returned by `-srg_trackedAutomatically` is changed after a view controller was already displayed,
 *              no page view will be automatically sent afterwards. For this reason, it is recommended that the value
 *              returned by `-srg_trackedAutomatically` should never be dynamic: Either return `YES` or `NO` depending
 *              on which kind of tracking you need.
 */
@property (nonatomic, readonly, getter=srg_isTrackedAutomatically) BOOL srg_trackedAutomatically;

/**
 *  Return the levels (position in the view hierarchy) to be sent for view event measurement.
 *
 *  @return The array of levels, in increasing depth order.
 */
@property (nonatomic, readonly, nullable) NSArray<NSString *> *srg_pageViewLevels;

/**
 *  Additional information (labels) which must be sent with a view event. By default no custom labels are sent.
 */
@property (nonatomic, readonly, nullable) SRGAnalyticsPageViewLabels *srg_pageViewLabels;

/**
 *  Return `YES` if the view controller was opened from a push notification. If not implemented, it is assumed the
 *  view controller was not opened from a push notification.
 *
 *  @return `YES` if the presented view controller has been opened from a push notification, `NO` otherwise.
 */
@property (nonatomic, readonly, getter=srg_isOpenedFromPushNotification) BOOL srg_openedFromPushNotification;

@end

/**
 *  Protocol for custom containers to implement automatic page view tracking propagation to their children. Standard
 *  `UIKit` containers already conform to this protocol and do not require any additional work. For other custom
 *  containers conforming to this protocol is required so that automatic page views can be correctly propagated.
 *
 *  The implementation of a custom container might also need to inform the automatic page view tracking engine of
 *  child controller appearance, see `-srg_setNeedsAutomaticPageViewTrackingInChildViewController:`.
 */
@protocol SRGAnalyticsContainerViewTracking

/**
 *  Must return the currently active child view controllers in the container, i.e. those currently presented to the
 *  user. Some examples:
 *    - The top view controller of a custom navigation controller.
 *    - The currently displayed view controller of a custom tab bar controller.
 *    - All view controllers displayed side by side in a custom split view controller.
 */
@property (nonatomic, readonly) NSArray<UIViewController *> *srg_activeChildViewControllers;

@end

/**
 *  Analytics extensions for view controller tracking.
 */
@interface UIViewController (SRGAnalytics)

/**
 *  Call this method to send a page view event manually for the receiver. This method does nothing if the receiver does
 *  not conform to the `SRGAnalyticsViewTracking` protocol.
 *
 *  @discussion Mostly useful when `-srg_trackedAutomatically` has been implemented and returns `NO` (see above).
 */
- (void)srg_trackPageView;

/**
 *  Call this method after a child view controller has been added to a container to inform the automatic page view
 *  tracking engine that automatic propagation should be considered again.
 *
 *  Has no effect if the receiver does not conform to `SRGAnalyticsContainerViewTracking`, or if the specified
 *  view controller is not a child of the receiver.
 *
 *  @discussion Required for containers displaying sibling view controllers, keeping them alive while inactive. For
 *              containers discarding children which have disappeared (similar to what `UINavigationController` does),
 *              calling this method is not required, as standard view appearance suffices to trigger automatic page
 *              views.
 */
- (void)srg_setNeedsAutomaticPageViewTrackingInChildViewController:(UIViewController *)childViewController;

@end

/**
 *  Standard analytics containment support for `UINavigationController`.
 */
@interface UINavigationController (SRGAnalytics) <SRGAnalyticsContainerViewTracking>

@end

/**
*  Standard analytics containment support for `UIPageViewController`.
*/
@interface UIPageViewController (SRGAnalytics) <SRGAnalyticsContainerViewTracking>

@end

/**
 *  Standard analytics containment support for `UISplitViewController`.
 */
@interface UISplitViewController (SRGAnalytics) <SRGAnalyticsContainerViewTracking>

@end

/**
 *  Standard analytics containment support for `UITabBarController`.
 */
@interface UITabBarController (SRGAnalytics) <SRGAnalyticsContainerViewTracking>

@end

NS_ASSUME_NONNULL_END
