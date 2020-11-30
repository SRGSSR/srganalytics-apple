Getting started
===============

The SRG Analytics library is made of several frameworks:

* A main `SRGAnalytics.framework` which supplies the singleton responsible of gathering measurements (tracker).
* A companion optional `SRGAnalyticsMediaPlayer.framework` responsible of stream measurements for applications using our [SRG Media Player library](https://github.com/SRGSSR/srgmediaplayer-apple).
* A companion optional `SRGAnalyticsDataProvider.framework` transparently forwarding stream measurement analytics labels received from Integration Layer services by the [SRG Data Provider library](https://github.com/SRGSSR/srgdataprovider-apple).

## Starting the tracker

Before measurements can be collected, the tracker singleton responsible of all analytics data gathering must be started. You should start the tracker as soon as possible, usually in your application delegate `-application:didFinishLaunchingWithOptions:` method implementation. Startup requires a single configuration parameter to be provided:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // ...
    
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRF
                                                                                                       container:3
                                                                                                        siteName:@"srf-app-site"
                                                                                             netMetrixIdentifier:@"srf-app-identifier"];
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration];
                                                     
    // ...
}
```

The various setup parameters to use must be obtained from the team responsible of measurements for your application.

For unit tests, you can set the `unitTesting` flag to emit notifications which can be used to check when analytics information is sent, and whether it is correct.

Once the tracker has been started your application can collect analytics data.

#### Remark

If and only if your application data will be analyzed by your business unit (and not by the SRG SSR General Direction), set the configuration `centralized` boolean to `NO`. Otherwise leave the default value as is, which means your application data will be analyzed according to the SRG SSR General Direction rules.

## Application information

The application information is automatically extracted from your application `Info.plist` file:

- The application name is given by `CFBundleName`.
- The application version is given by `CFBundleShortVersionString`.

If your application has an Android equivalent, you should ensure that both the Android, iOS and tvOS versions use the same application name.

## Measurement information

Measurement information, often referred to as labels, is provided in the form of dictionaries mapping strings to strings. Part of the information sent in events follows SRG measurement guidelines and is handled internally, but you can add arbitrary information for your own measurement purposes if needed (see below how this is done for the various events your application can generate).

Be careful when using custom labels, though, and ensure your custom keys do not match reserved values by using appropriate naming conventions (e.g. a prefix). Also check with the measurement team whether the custom labels you are using is supported.

## Measuring page views

View controllers represent the units of screen interaction in an application, this is why page view measurements are primarily made on view controllers. All methods and protocols for view controller tracking have been gathered in the `UIViewController+SRGAnalytics.h` file.

View controller measurement is an opt-in, in other words no view controller is tracked by default. For a view controller to be tracked, the recommended approach is to have it conform to the `SRGAnalyticsViewTracking` protocol. This protocol requires a single method to be implemented, returning the page view title to be used for measurements. By default, once a view controller implements the `SRGAnalyticsViewTracking` protocol, it automatically generates a page view when it first appears on screen, and when the application wakes up from background with the view controller displayed.

The `SRGAnalyticsViewTracking` protocol supplies optional methods to specify other custom measurement information (labels). If the required information is not available when the view controller appears, you can disable automatic tracking by implementing the optional `-srg_isTrackedAutomatically` protocol method, returning `NO`. You are then responsible of calling `-trackPageView` on the view controller when the data required by the page view is available, as well as when the application returns from background.

Automatic page view measurements are propagated through your application view controller hierarchy when needed. If your application uses custom containers, you should have conform to the `SRGAnalyticsContainerViewTracking` protocol so that they are tracked accurately and call `srg_setNeedsAutomaticPageViewTrackingInChildViewController:` to inform the layout engine of child controller appearance. If a container does not implement `SRGAnalyticsContainerViewTracking` page view measurements will be propagated automatically to all its children view controllers. Refer to the related header documentation for more information.

If a view can be opened from a push notification, you must implement the `-srg_openedFromPushNotification` method and return `YES` when the view controller was actually opened from a push notification.

#### Remark

If your application needs to track views instead of view controllers, you can still perform tracking using the `-[SRGAnalyticsTracker trackPageViewWithTitle:levels:labels:fromPushNotification:]` method.

### Example

Consider you have a `HomeViewController` view controller you want to track. First make it conform to the `SRGAnalyticsViewTracking` protocol:

```objective-c
@interface HomeViewController : UIViewController <SRGAnalyticsViewTracking>

@end
```

and implement the methods you need to supply measurement information:

```objective-c
@implementation HomeViewController

// Mandatory
- (NSString *)srg_pageViewTitle
{
    return @"home";
}

- (SRGAnalyticsPageViewLabels *)srg_pageViewLabels
{
    SRGAnalyticsPageViewLabels *labels = [[SRGAnalyticsPageViewLabels alloc] init];
    labels.customInfo = @{ @"MYAPP_CATEGORY" : @"general",
                           @"MYAPP_TIME" : @"1499319314" };
    labels.comScoreCustomInfo = @{ @"myapp_category" : @"gen" };
    return labels;
}

@end
```

When the view is opened for the first time, or if the view is visible on screen when waking up the application, this information will be automatically sent.

Note that the labels might differ depending on the service they are sent to. Be sure to apply the conventions required for measurements of your application. Moreover, custom information requires the corresponding variables to be defined for TagCommander first (unlike comScore information which can be freely defined).

## Measuring application functionalities

To measure any kind of application functionality, you typically use hidden events. Those can be emitted by calling the corresponding methods on the tracker singleton itself. For example, you could send the following event when the user taps on a player full-screen button within your application:

```objective-c
[SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:@"full-screen"];
```

Custom labels can also be used to send any additional measurement information you could need.

## Measuring SRG Media Player media consumption

To measure media consumption for [SRG Media Player](https://github.com/SRGSSR/srgmediaplayer-apple) controllers, you need to add the `SRGAnalyticsMediaPlayer.framework` companion framework to your project. As soon the framework has been added, it starts tracking any `SRGMediaPlayerController` instance by default. 

You can disable tracking by setting the `SRGMediaPlayerController` `tracked` property to `NO`. If you don't want the player to send any media playback events, you should perform this setup before actually beginning playback. You can still toggle the property on or off at any time if needed.

Measurement information (labels) can be associated with the content being played. This is achieved by providing an `analyticsLabels` dictionary to playback methods available from `SRGMediaPlayerController+SRGAnalytics.h`.

## Automatic media consumption measurement labels using the SRG Data Provider library

Our services directly supply the custom analytics labels which need to be sent with media consumption measurements. If you are using our [SRG DataProvider library](https://github.com/SRGSSR/srgdataprovider-apple) in your application, be sure to add the `SRGAnalytics_SRGDataProvider.framework` companion framework to your project as well, which will take care of the whole process for you.

This framework adds a category `SRGMediaPlayerController (SRGAnalyticsDataProvider)`, which adds playback methods for media compositions to `SRGMediaPlayerController`. To play a media composition retrieved from an `SRGDataProvider` and have all measurement information automatically associated with the playback, simply call:

```objective-c
[mediaPlayerController playMediaComposition:mediaComposition
                                 atPosition:nil
		               withPreferredSettings:nil
                                   userInfo:nil];
```

on an `SRGMediaPlayerController` instance.

Nothing more is required for correct media consumption measurements. During playback all analytics labels for the content and its segments will be transparently managed for you.

## Automatic identity measurement labels using the SRG Identity library

If you are using our [SRG Identity library](https://github.com/SRGSSR/srgidentity-apple) in your application, be sure to add the `SRGAnalytics_SRGIdentity.framework` companion framework to your project as well. This ensures that an identity can be automatically associated with analytics measurements.

This framework adds a category `SRGAnalyticsTracker (SRGAnalyticsIdentity)`, which provides an additional `-startWithConfiguration:identityService:` method to `SRGAnalyticsTracker`. To automatically asssociate an identity with analytics measurements, start your analytics tracker with this method instead of the orginal one:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // ...
    
    SRGIdentityService.currentIdentityService = [[SRGIdentityService alloc] initWith...];
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWith...];
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration identityService:SRGIdentityService.currentIdentityService];
                                                     
    // ...
}
```

## Manual resource retrieval

Using the `SRGAnalyticsDataProvider.framework` companion framework is all you need to play a media with complete analytics information, right within an SRG Media Player controller instance.

In the case you need to play a resource without an SRG Media Player controller instance (e.g. with Google Cast default receiver), the companion framework provides the `-[SRGMediaComposition playbackContextWithPreferredSettings:contextBlock:]` method, with which you can find the proper resource to play.

## Thread-safety

The library is intended to be used from the main thread only. Trying to use if from background threads results in undefined behavior.

## App Transport Security (ATS)

In a near future, Apple will favor HTTPS over HTTP, and require applications to explicitly declare potentially insecure connections. These guidelines are referred to as [App Transport Security (ATS)](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW33).

For information about how you should configure your application to access our services, please refer to the dedicated [SRG Data Provider wiki topic](https://github.com/SRGSSR/srgdataprovider-apple/wiki/App-Transport-Security-(ATS)).
