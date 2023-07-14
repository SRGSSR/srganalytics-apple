//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsConfiguration.h"
#import "SRGAnalyticsEventLabels.h"
#import "SRGAnalyticsPageViewLabels.h"
#import "SRGAnalyticsTrackerDataSource.h"

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  The analytics tracker is a singleton instance responsible of tracking usage of an application, sending measurements
 *  to Commanders Act (internal analytics) and comScore (Mediapulse official audience measurements). The usage data is
 *  simply a collection of key-values (both strings), named labels, which can then be used by data analysts in studies
 *  and reports.
 *
 *  The analytics tracker implementation follows the SRG SSR guidelines for application measurements (mostly label name
 *  conventions) and is therefore only intended for use by applications produced under the SRG SSR umbrella.
 *
 *  ## Measurements
 *
 *  The SRG Analytics library supports three kinds of measurements:
 *    - View events: Appearance of views (page views), which makes it possible to track which content is seen by users.
 *    - Events: Custom events which can be used for measuresement of application functionalities.
 *    - Stream playback events: Measurements for audio and video consumption.
 *
 *  For all kinds of measurements, required information must be provided through mandatory parameters, and optional
 *  labels can be provided through an optional labels object. In all cases, mandatory and optional information is
 *  transparently routed to the analytics services.
 *
 *  ## Usage
 *
 *  Using SRGAnalytics in your application is intended to be as easy as possible. Note that since the analytics tracker is
 *  a singleton, you cannot currently perform measurements related to several business units within a single application.
 *
 *  To track application usage:
 *
 *  1. Start the tracker early in your application lifecycle, for example in your application delegate
 *     `-application:didFinishLaunchingWithOptions:` implementation, by calling the `-startWithConfiguration:` method. 
 *     This method expect a single configuration object containing all analytics setup information.
 *  2. To track page views related to view controllers, have them conform to the `SRGAnalyticsViewTracking` protocol.
 *     View controllers conforming to this protocol are automatically tracked by default, but this behavior can be
 *     tailored to your needs, especially if the time at which the measurement is made (when the view appears) is 
 *     inappropriate. Please refer to the `SRGAnalyticsViewTracking` documentation for more information. If your
 *     application uses plain views (not view controllers) which must be tracked as well, you can still perform
 *     manual tracking via the `-[SRGAnalyticsTracker trackPageViewWithTitle:levels:labels:fromPushNotification:]`
 *     method.
 *  3. When you need to track specific functionalities in your application (e.g. the use of some interface button
 *     or of some feature of your application), send a event using one of the `-trackEvent...` methods available
 *     from `SRGAnalyticsTracker`.
 *  4. If you need to track media playback using SRG MediaPlayer, you must add the SRGAnalyticsMediaPlayer subframework
 *     to your project (@see `SRGMediaPlayerController+SRGAnalyticsMediaPlayer.h` for more information). You are 
 *     still responsible of providing most metadata associated with playback (e.g. title or duration of what is 
 *     being played) when calling one of the playback methods provided by this subframework.
 *  5. If medias you play are retrieved using our SRG DataProvider library, you must add the SRGAnalyticsDataProvider
 *     subframework to your project as well (@see `SRGMediaPlayerController+SRGAnalyticsDataProvider.h` for more 
 *     information). In this case, all mandatory stream measurement metadata will be automatically provided when
 *     playing the content through one of the playback methods made available by this subframework.
 */
NS_EXTENSION_UNAVAILABLE("SRG Analytics does not support application extensions")
@interface SRGAnalyticsTracker : NSObject

/**
 *  The tracker singleton.
 */
@property (class, nonatomic, readonly) SRGAnalyticsTracker *sharedTracker;

/**
 *  Start the tracker. This is required to specify for which business unit you are tracking events, as well as to
 *  where they must be sent on the comScore and Commanders Act services. Attempting to track view, stream or other
 *  events without starting the tracker has no effect.
 *
 *  @param configuration The configuration to use. This configuration is copied and cannot be changed afterwards.
 */
- (void)startWithConfiguration:(SRGAnalyticsConfiguration *)configuration;

/**
 *  Start the tracker. This is required to specify for which business unit you are tracking events, as well as to
 *  where they must be sent on the comScore and TagCommander services. Attempting to track view, hidden or stream
 *  events without starting the tracker has no effect.
 *
 *  @param configuration The configuration to use. This configuration is copied and cannot be changed afterwards.
 *  @param dataSource    The data source for the global labels.
 */
- (void)startWithConfiguration:(SRGAnalyticsConfiguration *)configuration
                    dataSource:(nullable id<SRGAnalyticsTrackerDataSource>)dataSource;

/**
 *  The tracker configuration with which the tracker was started.
 */
@property (nonatomic, readonly, copy, nullable) SRGAnalyticsConfiguration *configuration;

@end

/**
 *  @name Event tracking
 */
@interface SRGAnalyticsTracker (EventTracking)

/**
 *  Send a event with the specified name.
 *
 *  @param name The event name.
 *
 *  @discussion If the name is empty, no event will be sent.
 */
- (void)trackEventWithName:(NSString *)name;

/**
 *  Send a event with the specified name.
 *
 *  @param name           The event name.
 *  @param labels         Information to be sent along the event and which is meaningful for your application measurements.
 *
 *  @discussion If the name is `nil`, no event will be sent.
 */
- (void)trackEventWithName:(NSString *)name
                    labels:(nullable SRGAnalyticsEventLabels *)labels;

@end

/**
 *  Checked page view tracking, preventing page views from being emitted while the application is in the background.
 *  This is the expected general behavior for most applications.
 */
@interface SRGAnalyticsTracker (CheckedPageViewTracking)

/**
 *  Track a page view (not associated with a push notification). Does nothing when the application is in the background.
 *
 *  @param title  The page title. If the title is empty, no event will be sent.
 *  @param levels An array of levels in increasing order, describing the position of the view in the hierarchy.
 *
 *  @discussion This method is primarily available for page view tracking not related to a view controller. If your page view
 *              is related to a view controller, the recommended way of tracking the view controller is by having it conform
 *              to the `SRGAnalyticsViewTracking` protocol.
 */
- (void)trackPageViewWithTitle:(NSString *)title
                        levels:(nullable NSArray<NSString *> *)levels;

/**
 *  Track a page view. Does nothing when the application is in the background.
 *
 *  @param title                The page title. If the title is empty, no event will be sent.
 *  @param levels               An array of levels in increasing order, describing the position of the view in the hierarchy.
 *  @param labels               Additional custom labels.
 *  @param fromPushNotification `YES` iff the view is opened from a push notification.
 *
 *  @discussion This method is primarily available for page view tracking not related to a view controller. If your page view
 *              is related to a view controller, the recommended way of tracking the view controller is by having it conform
 *              to the `SRGAnalyticsViewTracking` protocol.
 */
- (void)trackPageViewWithTitle:(NSString *)title
                        levels:(nullable NSArray<NSString *> *)levels
                        labels:(nullable SRGAnalyticsPageViewLabels *)labels
          fromPushNotification:(BOOL)fromPushNotification;

@end

/**
 *  Unchecked page view tracking, sending page views no matter the application state. Only use unchecked tracking if
 *  your application has special needs requiring some pages views to be emitted while the application is in background.
 *  This is for example the case if your application runs a secondary external window while it might itself be in the
 *  background (e.g. CarPlay scene).
 *
 *  Be extremely careful when using the APIs below, as your application might be rejected if illegitmate page views are
 *  emitted in the background.
 */
@interface SRGAnalyticsTracker (UncheckedPageViewTracking)

/**
 *  Unchecked track a page view. The page view is emitted no matter the application state.
 *
 *  @param title  The page title. If the title is empty, no event will be sent.
 *  @param levels An array of levels in increasing order, describing the position of the view in the hierarchy.
 */
- (void)uncheckedTrackPageViewWithTitle:(NSString *)title
                                 levels:(nullable NSArray<NSString *> *)levels;

/**
 *  Unchecked track a page view. The page view is emitted no matter the application state.
 *
 *  @param title  The page title. If the title is empty, no event will be sent.
 *  @param levels An array of levels in increasing order, describing the position of the view in the hierarchy.
 *  @param labels Additional custom labels.
 */
- (void)uncheckedTrackPageViewWithTitle:(NSString *)title
                                 levels:(nullable NSArray<NSString *> *)levels
                                 labels:(nullable SRGAnalyticsPageViewLabels *)labels;

@end

@interface SRGAnalyticsTracker (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
