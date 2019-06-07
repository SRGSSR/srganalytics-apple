![SRG Media Player logo](README-images/logo.png)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

## About

The SRG Analytics library for iOS makes it easy to add usage tracking information to your applications, following the SRG SSR standards.

Measurements are based on events emitted by the application and collected by TagCommander, comScore and NetMetrix. 

The SRG Analytics library supports three kinds of measurements:

 * View events: Appearance of views (page views), which makes it possible to track which content is seen by users.
 * Hidden events: Custom events which can be used for measurement of application functionalities.
 * Stream playback events: Audio and video consumption measurements for application using our [SRG Media Player](https://github.com/SRGSSR/SRGMediaPlayer-iOS). Additional playback information (title, duration, etc.) must be supplied externally. For application using our [SRG Data Provider](https://github.com/SRGSSR/srgdataprovider-ios) library, though, this process is entirely automated.
 
## Compatibility

The library is suitable for applications running on iOS 9 and above. The project is meant to be opened with the latest Xcode version (currently Xcode 10).

## Contributing

If you want to contribute to the project, have a look at our [contributing guide](CONTRIBUTING.md).

## Installation

The library can be added to a project using [Carthage](https://github.com/Carthage/Carthage) by adding the following dependency to your `Cartfile`:
    
```
github "SRGSSR/srganalytics-ios"
```

For more information about Carthage and its use, refer to the [official documentation](https://github.com/Carthage/Carthage).

### Content protection

The `SRGAnalytics_DataProvider.framework` companion framework provides convenience methods for playing content delivered by our [SRG Data Provider](https://github.com/SRGSSR/srgdataprovider-ios) library. Not all content is publicly accessible for legal reasons, though, in particular livestreams or foreign TV series.

To play protected content, and provided you have been granted access to it, an internal [SRG Content Protection](https://github.com/SRGSSR/srgcontentprotection-ios) framework is available and must be added to your project `Cartfile` as well:

```
github "SRGSSR/srgcontentprotection-ios"
```

If you have no access to this repository, use the fake public replacement framework by adding the following dependency instead:

```
github "SRGSSR/srgcontentprotection-fake-ios"
```

When linking against the fake framework, some content (e.g. livestreams) will not be playable.

### Dependencies

Depending on your needs, the library requires the following frameworks to be added to any target requiring it:

* If you need analytics only, add the following frameworks to your target:
  * `ComScore`: comScore framework.
  * `libextobjc`: A utility framework.
  * `MAKVONotificationCenter`: A safe KVO framework.
  * `SRGAnalytics`: The main analytics framework.
  * `SRGLogger`: The framework used for internal logging.
  * `TCCore`: The core TagCommander framework.
  * `TCSDK`: The main TagCommander SDK framework.
* If you use our [SRG Media Player library](https://github.com/SRGSSR/SRGMediaPlayer-iOS) and want automatic media consumption tracking as well, add the following frameworks to your target:
  * `ComScore`: comScore framework.
  * `libextobjc`: A utility framework.
  * `MAKVONotificationCenter`: A safe KVO framework.
  * `SRGAnalytics`: The main analytics framework.
  * `SRGAnalytics_MediaPlayer`: The media player analytics companion framework.
  * `SRGLogger`: The framework used for internal logging.
  * `TCCore`: The core TagCommander framework.
  * `TCSDK`: The main TagCommander SDK framework.
* If you use our [SRG Data Provider library](https://github.com/SRGSSR/srgdataprovider-ios) to retrieve and play medias, add the following frameworks to your target:
  * `ComScore`: comScore framework.
  * `libextobjc`: A utility framework.
  * `MAKVONotificationCenter`: A safe KVO framework.
  * `Mantle`:  The framework used to parse the data.
  * `SRGAnalytics`: The main analytics framework.
  * `SRGAnalytics_DataProvider`: The data provider analytics companion framework.
  * `SRGAnalytics_MediaPlayer`: The media player analytics companion framework.
  * `SRGContentProtection`: The framework to enable playback of protected medias.
  * `SRGLogger`: The framework used for internal logging.
  * `SRGMediaPlayer`: The media player framework (if not already in your project).
  * `SRGNetwork`: A networking framework.
  * `TCCore`: The core TagCommander framework.
  * `TCSDK`: The main TagCommander SDK framework.
* If you use our [SRG Identity library](https://github.com/SRGSSR/srgidentity-ios) in your application, add the following frameworks to your target:
  * `ComScore`: comScore framework.
  * `libextobjc`: An utility framework.
  * `MAKVONotificationCenter`: A safe KVO framework.
  * `SRGAnalytics`: The main analytics framework.
  * `SRGAnalytics_Identity`: The identity analytics companion framework.
  * `SRGLogger`: The framework used for internal logging.
  * `TCCore`: The core TagCommander framework.
  * `TCSDK`: The main TagCommander SDK framework.

### Dynamic framework integration

1. Run `carthage update` to update the dependencies (which is equivalent to `carthage update --configuration Release`). 
2. Add the frameworks listed above and generated in the `Carthage/Build/iOS` folder to your target _Embedded binaries_.

If your target is building an application, a few more steps are required:

1. Add a _Run script_ build phase to your target, with `/usr/local/bin/carthage copy-frameworks` as command.
2. Add each of the required frameworks above as input file `$(SRCROOT)/Carthage/Build/iOS/FrameworkName.framework`.

### Static framework integration

1. Run `carthage update --configuration Release-static` to update the dependencies. 
2. Add the frameworks listed above and generated in the `Carthage/Build/iOS/Static` folder to the _Linked frameworks and libraries_ list of your target.
3. Also add any resource bundle `.bundle` found within the `.framework` folders to your target directly.
4. Some non-statically built framework dependencies are built in the `Carthage/Build/iOS` folder. Add them by following the _Dynamic framework integration_ instructions above.
5. Add the `-all_load` flag to your target _Other linker flags_.

## Building the project

A [Makefile](../Makefile) provides several targets to build and package the library. The available targets can be listed by running the following command from the project root folder:

```
make help
```

Alternatively, you can of course open the project with Xcode and use the available schemes.

## Usage

When you want to use classes or functions provided by the library in your code, you must import it from your source files first.

### Usage from Objective-C source files

Import the global header files using:

```objective-c
#import <SRGAnalytics/SRGAnalytics.h>	                            // For SRGAnalytics.framework
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>       // For SRGAnalytics_MediaPlayer.framework
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>     // For SRGAnalytics_DataProvider.framework
#import <SRGAnalytics_Identity/SRGAnalytics_Identity.h>             // For SRGAnalytics_Identity.framework
```

or directly import the modules themselves:

```objective-c
@import SRGAnalytics;                    // For SRGAnalytics.framework
@import SRGAnalytics_MediaPlayer;        // For SRGAnalytics_MediaPlayer.framework
@import SRGAnalytics_DataProvider;       // For SRGAnalytics_DataProvider.framework
@import SRGAnalytics_Identity;     	     // For SRGAnalytics_Identity.framework
```

### Usage from Swift source files

Import the modules where needed:

```swift
import SRGAnalytics                     // For SRGAnalytics.framework
import SRGAnalytics_MediaPlayer         // For SRGAnalytics_MediaPlayer.framework
import SRGAnalytics_DataProvider        // For SRGAnalytics_DataProvider.framework
import SRGAnalytics_Identity            // For SRGAnalytics_Identity.framework
```

### Info.plist settings for application installation measurements

The library automatically tracks which SRG SSR applications are installed on a user device, and sends this information. For this mechanism to work properly, though, your application **must** declare all official SRG SSR application URL schemes as being supported in its `Info.plist` file. 

This can be achieved as follows:

* Run the `LSApplicationQueriesSchemesGenerator.swift ` script found in the `Scripts` folder. This script automatically generates an `LSApplicationQueriesSchemesGenerator.plist` file in the folder you are running it from, containing an up-to-date list of SRG SSR application schemes.
* Open the generated `plist` file and either copy the `LSApplicationQueriesSchemes` to your project `Info.plist` file, or merge it with already existing entries.

If URL schemes declared by your application do not match the current ones, application installations will not be accurately reported, and error messages will be logged when the application starts (see _Logging_ below). This situation is not catastropic but should be fixed when possible to ensure better measurements.

#### Remark

The number of URL schemes an application declares is limited to 50. Please contact us if your application reaches this limit.

### Working with the library

To learn about how the library can be used, have a look at the [getting started guide](GETTING_STARTED.md).

### Logging

The library internally uses the [SRG Logger](https://github.com/SRGSSR/srglogger-ios) library for logging, with the following subsystems:

* `ch.srgssr.analytics` for `SRGAnalytics.framework` events.
* `ch.srgssr.analytics.mediaplayer` for `SRGAnalytics_MediaPlayer.framework` events.
* `ch.srgssr.analytics.dataprovider` for `SRGAnalytics_DataProvider.framework` events.
* `ch.srgssr.analytics.identity` for `SRGAnalytics_Identity.framework` events.

This logger either automatically integrates with your own logger, or can be easily integrated with it. Refer to the SRG Logger documentation for more information.

## Advertising Identifier (IDFA)

SRG Analytics internally links against `AdSupport.framework` and therefore requires extra care when submitting an application to the App Store.

As part of your application submission process, you must provide reasons for Advertising Identifier usage. Be sure to tick the following checkboxes when asked to:

* _Attribute this app installation to a previously served advertisement_.
* _Attribute an action taken within this app to a previously served advertisement_.

Since SRG SSR applications do not contain any ads, you must leave the _Serve advertisements within the app_ checkbox unticked.

## Demo project

To test what the library is capable of, run the associated demo.

## Migration from previous major versions

For information about migration from older major library versions, please read the [migration guide](MIGRATION_GUIDE.md).

## License

See the [LICENSE](../LICENSE) file for more information.