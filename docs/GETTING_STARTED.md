Getting started
===============

The SRG Analytics library is made of several frameworks:

* A main `SRGAnalytics.framework` which supplies the singleton responsible of gathering measurements (tracker).
* A companion option `SRGAnalyticsSwiftUI.framework` for page view tracking of SwiftUI views.
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
                                                                                                        siteName:@"srf-app-site"];
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

Application name and version are required in analytics measurements. This information is automatically extracted from your application `Info.plist` which must therefore be properly configured to send correct values:

- The [application name](https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundlename) is extracted from `CFBundleName`.
- The [application version](https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleshortversionstring) is extracted from `CFBundleShortVersionString`.  

The application name must be consistent for all platforms your product is available on (e.g. iOS, tvOS and Android) so that measurements can be properly consolidated. Known expected application names are available from the corresponding [wiki page](https://confluence.srg.beecollaboration.com/display/INTFORSCHUNG/Guidance+Implementation+Apps). Should your product be new, please use the contact information available from this wiki page to request a dedicated application name.

## Measurement information

Measurement information, often referred to as labels, is provided in the form of dictionaries mapping strings to strings. Part of the information sent in events follows SRG measurement guidelines and is handled internally, but you can add arbitrary information for your own measurement purposes if needed (see below how this is done for the various events your application can generate).

Be careful when using custom labels, though, and ensure your custom keys do not match reserved values by using appropriate naming conventions (e.g. a prefix). Also check with the measurement team whether the custom labels you are using is supported.

## Measuring page views (UIKit)

View controllers represent the units of screen interaction in an application, this is why page view measurements are primarily made on view controllers. All methods and protocols for view controller tracking have been gathered in the `UIViewController+SRGAnalytics.h` file.

### View controller tracking

View controller measurement is an opt-in, in other words no view controller is tracked by default. For a view controller to be tracked the recommended approach is to have it conform to the `SRGAnalyticsViewTracking` protocol. This protocol requires a single method to be implemented, returning the page view title to be used for measurements. By default, once a view controller implements the `SRGAnalyticsViewTracking` protocol, it automatically generates a page view when it first appears on screen and when the application wakes up from background with the view controller displayed.

The `SRGAnalyticsViewTracking` protocol supplies optional methods to specify other custom measurement information (labels). If the required information is not available when the view controller appears you can disable automatic tracking by implementing the optional `-srg_isTrackedAutomatically` protocol method, returning `NO`. You are then responsible of calling `-trackPageView` on the view controller when the data required by the page view is available, as well as when the application returns from background.

### Containers

Automatic page view measurements are propagated through your application view controller hierarchy when needed. If your application uses custom containers you should have them conform to the `SRGAnalyticsContainerViewTracking` protocol so that they are tracked correctly. You must also call `srg_setNeedsAutomaticPageViewTrackingInChildViewController:` at the appropriate time to inform the analytics engine of child controller appearance.

All standard UIKit containers (`UINavigationController`, `UIPageViewController`, `UISplitViewController` and `UITabBarController`) support container view tracking, so provided you use standard containers only no additional work is required. If you use custom containers, though, you must ensure they implement `SRGAnalyticsContainerViewTracking` so that page view measurements can be automatically propagated to their children view controllers. Refer to the related header documentation for more information

### Push notifications

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

## Measuring page views (SwiftUI)

Measuring page views in SwiftUI is simply made using a view modifier:

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            // ...
        }.tracked(withTitle: "home")
    }
}
```

## Measuring page views when displaying web content

Apps might display or embed web content in various ways, whether this content is part of SRG SSR offering or external to the company (e.g. some arbitrary Youtube page). 

SRG SSR websites must themselves implement page view tracking in JavaScript, so that usage data can be properly collected when a browser (desktop and mobile Safari, Chrome, Edge, etc.) is used to navigate them. External websites, while of course not tracked, often provide a way to navigate to an SRG SSR website by following some series of hyperlinks.

**To comply with Mediapulse guidelines, it is especially important that no tracked SRG SSR web content is displayed while a tracked app is running in the foreground.** The reason is that two separate analytics sessions would then coexist for native and web content with overlapping measurements (e.g. session duration), which is strictly forbidden by Mediapulse.

This section discusses how you should display web content in your application so that Mediapulse requirements are correctly fulfilled.

### Glossary

In the following we refer to the various ways of displaying web content as follows:

- Web view: Component which an app can use to embed web content in a flexible way (`WKWebView`).
- In-app web browser: Web browser interface which can be used to display web content without leaving an app (`SFSafariViewController`).
- Device browser: Any standalone browser app that can be used on a device (e.g. Safari Mobile, Google Chrome, etc.). To invoke the default web browser use the `-[UIApplication openURL:options:completionHandler:]` API, which also provides support for deep linking for apps supporting it.

### Using the device browser

Most of the time it is very difficult or nearly [impossible](https://en.wikipedia.org/wiki/Wikiracing) to guarantee that, starting from some random web page (part of SRG SSR offering or not) you cannot somehow reach a tracked SRG SSR web page. For example, even if your app opens a Wikipedia page about some random topic, it is always possible that the user can search for an SRG SSR article and finally reach one of our tracked websites. 

In such cases you should present the web content with the device browser. This ensures your app is automatically sent to the background so that Mediapulse requirements are guaranteed to be fulfilled, no matter how the user navigates the web content.

This approach works well for apps which present loosly related web content, for example a link to some article, to a user guide or to legal information pages. 

#### Examples

- Mostly native application with documentation accessible via web pages.
- Player application offering a few links to articles related to a media stemming from various sources.

### Displaying web content in app

Your app might need to display web content with tight integration into its native user interface. In such cases you must consider the web view or in-app browser approaches.

If the web content you want to display belongs to the SRG SSR, it must provide a way to disable JavaScript tracking entirely (e.g. with a special resource path or parameter) so that it can be displayed while your application is in foreground without overlapping measurements.

Moreover, no matter whether you display an SRG SSR web page or an external one, you must ensure that the user is never able to navigate to a tracked web page, even in convoluted ways. Here are a few possible strategies to achieve this result:

- Your application might display an SRG SSR web page offering reduced navigation abilities (e.g. no footer, no header, no links) so that the user cannot navigate away, or is forced to stay within a few untracked pages with no possibility to leave.
- Your application might observe web navigation (e.g. by implementing `WKNavigationDelegate` if you are using `WKWebView`) and inhibit navigation to tracked SRG SSR websites. Alternatively it can force tracked SRG SSR websites to be opened in the device browser instead.

Should you have to display web content within your application, please thoroughfully check that Mediapulse requirements are fulfilled, otherwise your application might be excluded from official reports when tested.

#### Examples

- News application displaying articles from the companion website as HTML.
- Login web page displayed using `ASAuthenticationServices`, which itself uses the in-app browser for presentation.

### Testing tool

The SRG Analytics demo provides a web testing tool which lets you display any web page in the context of a tracked app. You can use a proxy tool (e.g. [Charles proxy](https://www.charlesproxy.com)) to check how some web page behaves in the context of an app, whether this page is opened while the app is still in foreground (web view or in-app browser) or while the app is in background (device browser).

## Measuring external scenes

Usual page view tracking methods or protocols ensure page views are never sent while the application is in the background, as this could lead to your application being rejected by Mediapulse.

In some special cases like CarPlay, though, your application might display a second scene externally while itself staying in background. `SRGAnalyticsTracker` provides unchecked tracking methods to let you send page view events while the user is navigating your external user interface.

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
