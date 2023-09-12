[![SRG Analytics logo](README-images/logo.png)](https://github.com/SRGSSR/srganalytics-apple)

[![GitHub releases](https://img.shields.io/github/v/release/SRGSSR/srganalytics-apple)](https://github.com/SRGSSR/srganalytics-apple/releases) [![platform](https://img.shields.io/badge/platfom-ios%20%7C%20tvos-blue)](https://github.com/SRGSSR/srganalytics-apple) [![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager) [![GitHub license](https://img.shields.io/github/license/SRGSSR/srganalytics-apple)](https://github.com/SRGSSR/srganalytics-apple/blob/master/LICENSE)

## About

The SRG Analytics library makes it easy to add usage tracking information to your iOS and tvOS applications, following the SRG SSR standards.

Measurements are based on events emitted by the application and sent to Commanders Act (for internal analytics purposes) as well as Mediapulse (for official audience measurements, via comScore).

The SRG Analytics library supports three kinds of measurements:

 * View events: Appearance of views (page views), which makes it possible to track which content is seen by users.
 * Events: Custom events which can be used for measurement of application functionalities.
 * Stream playback events: Audio and video consumption measurements for application using our [SRG Media Player](https://github.com/SRGSSR/srgmediaplayer-apple). Additional playback information (title, duration, etc.) must be supplied externally. For application using our [SRG Data Provider](https://github.com/SRGSSR/srgdataprovider-apple) library, though, this process is entirely automated.
 * Integration with our [SRG Identity](https://github.com/SRGSSR/srgidentity-apple) library.
 
## Compatibility

The library is suitable for applications running on iOS 12, tvOS 12 and above. The project is meant to be compiled with the latest Xcode version.

## Contributing

If you want to contribute to the project, have a look at our [contributing guide](CONTRIBUTING.md).

## Integration

The library must be integrated using [Swift Package Manager](https://swift.org/package-manager) directly [within Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app). You can also declare the library as a dependency of another one directly in the associated `Package.swift` manifest.

### Libraries

The library is made of serveral smaller libraries. Which ones your project must link against depends on your needs:

- If you only need basic view and event tracking, just link against `SRGAnalytics`. If you need to track SwiftUI views link against `SRGAnalyticsSwiftUI` as well.
- If you need [SRG Media Player](https://github.com/SRGSSR/srgmediaplayer-apple) media playback tracking, also link against `SRGAnalyticsMediaPlayer`.
- If you need SRG standard media playback tracking with associated media metadata retrieved by [SRG Data Provider](https://github.com/SRGSSR/srgdataprovider-apple), also link against `SRGAnalyticsDataProvider`. This library provides several playback helpers you should use to ensure that context information is complete when playing a media.
- If you are using [SRG Identity](https://github.com/SRGSSR/srgidentity-apple) in your project, also link against `SRGAnalyticsIdentity`.

### Info.plist settings for application installation measurements

The library automatically tracks which SRG SSR applications are installed on a user device, and sends this information. For this mechanism to work properly, though, your application **must** declare all official SRG SSR application URL schemes as being supported in its `Info.plist` file. 

This can be achieved as follows:

* Run the `LSApplicationQueriesSchemesGenerator.swift ` script found in the `Scripts` folder. This script automatically generates an `LSApplicationQueriesSchemesGenerator.plist` file in the folder you are running it from, containing an up-to-date list of SRG SSR application schemes.
* Open the generated `plist` file and either copy the `LSApplicationQueriesSchemes` to your project `Info.plist` file, or merge it with already existing entries.

If URL schemes declared by your application do not match the current ones, application installations will not be accurately reported, and error messages will be logged when the application starts (see _Logging_ below). This situation is not catastropic but should be fixed when possible to ensure better measurements.

#### Remark

The number of URL schemes an application declares is limited to 50. Please contact us if your application reaches this limit.

## Usage

When you want to use classes or functions provided by one of the librares in your code, you must import it from your source files first. In Objective-C:

```objective-c
@import SRGAnalytics;
@import SRGAnalyticsMediaPlayer;
@import SRGAnalyticsDataProvider;
@import SRGAnalyticsIdentity;
```

or in Swift:

```swift
import SRGAnalytics
import SRGAnalyticsSwiftUI
import SRGAnalyticsMediaPlayer
import SRGAnalyticsDataProvider
import SRGAnalyticsIdentity
```

### Working with the library

To learn about how the library can be used, have a look at the [getting started guide](GETTING_STARTED.md).

### Logging

The library internally uses the [SRG Logger](https://github.com/SRGSSR/srglogger-apple) library for logging, with the following subsystems:

* `ch.srgssr.analytics` for `SRGAnalytics` events.
* `ch.srgssr.analytics.mediaplayer` for `SRGAnalyticsMediaPlayer` events.
* `ch.srgssr.analytics.dataprovider` for `SRGAnalyticsDataProvider` events.
* `ch.srgssr.analytics.identity` for `SRGAnalyticsIdentity` events.

This logger either automatically integrates with your own logger, or can be easily integrated with it. Refer to the SRG Logger documentation for more information.

## App Privacy details on the App Store

You are required to provide additional information about the data collected by your app and how it is used. Please refer to our [associated documentation](https://github.com/SRGSSR/srgletterbox-apple/wiki/App-Privacy-details-on-the-App-Store) for more information.

## Demo project

To test what the library is capable of, run the associated demo.

## License

See the [LICENSE](../LICENSE) file for more information.
