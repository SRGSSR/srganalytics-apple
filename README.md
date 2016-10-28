![SRG Media Player logo](README-images/logo.png)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

## About

The SRG Analytics library for iOS makes it easy to add usage tracking information to your applications, following the SRG SSR standards.

Measurements are based on events emitted by the application, and collected by comScore and NetMetrix. Currently, the following kinds of events are supported

 * View events: Appearance of views (page views), which makes it possible to track which content is seen by users
 * Hidden events: Custom events which can be used for measuresement of application functionalities
 * Media playback events: Measurements for audio and video consumption in conjunction with our [SRG Media Player library](https://github.com/SRGSSR/SRGMediaPlayer-iOS)

Moreover, if you are retrieving your data using our [SRG Data Provider library](https://github.com/SRGSSR/srgdataprovider-ios), a bridge framework is also provided so that analytics received from the service are transparently forwarded to the SRG Analytics library.
 
## Compatibility

The library is suitable for applications running on iOS 8 and above. The project is meant to be opened with the latest Xcode version (currently Xcode 8).

## Installation

The library can be added to a project using [Carthage](https://github.com/Carthage/Carthage)  by adding the following dependency to your `Cartfile`:
    
```
github "SRGSSR/srganalytics-ios"
```

Then run `carthage update --platform iOS` to update the dependencies. You will need to manually add one or several of the `.framework`s generated in the `Carthage/Build/iOS` folder to your projet, depending on your needs:

* If you need analytics only, add the following frameworks to your project:
  * `SRGAnalytics.framework`: The main analytics framework
  * `SRGLogger.framework`: The framework used for internal logging
  * `ComScore.framework`: comScore framework
  * `libextobjc.framework`: A utility framework
* If you use our [SRG Media Player library](https://github.com/SRGSSR/SRGMediaPlayer-iOS) and want media consumption tracking as well, add the following frameworks to your project:
  * `SRGAnalytics.framework`: The main analytics framework
  * `SRGAnalytics_MediaPlayer.framework`: The media player analytics companion framework
  * `SRGLogger.framework`: The framework used for internal logging
  * `ComScore.framework`: comScore framework
  * `libextobjc.framework`: A utility framework
* If you use our [SRG Data Provider library](https://github.com/SRGSSR/srgdataprovider-ios) to retrieve data, add the following frameworks to your project:
  * `SRGAnalytics.framework`: The main analytics framework
  * `SRGAnalytics_MediaPlayer.framework`: The media player analytics companion framework
  * `SRGAnalytics_DataProvider.framework`: The data provider analytics companion framework
  * `SRGLogger.framework`: The framework used for internal logging
  * `ComScore.framework`: comScore framework
  * `SRGMediaPlayer.framework`: The media player framework (if not already in your project)
  * `Mantle.framework`:  The framework used to parse the data
  * `libextobjc.framework`: A utility framework
  
For more information about Carthage and its use, refer to the [official documentation](https://github.com/Carthage/Carthage).

## Usage

When you want to classes or functions provided by the library in your code, you must import it from your source files first.

### Usage from Objective-C source files

Import the global header files using:

```objective-c
#import <SRGAnalytics/SRGAnalytics.h>	                            // For SRGAnalytics.framework
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>       // For SRGAnalytics_MediaPlayer.framework
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>     // For SRGAnalytics_DataProvider.framework
```

or directly import the modules themselves:

```objective-c
@import SRGAnalytics;                    // For SRGAnalytics.framework
@import SRGAnalytics_MediaPlayer;        // For SRGAnalytics_MediaPlayer.framework
@import SRGAnalytics_DataProvider;		 // For SRGAnalytics_DataProvider.framework
```

### Usage from Swift source files

Import the modules where needed:

```swift
import SRGAnalytics                     // For SRGAnalytics.framework
import SRGAnalytics_MediaPlayer         // For SRGAnalytics_MediaPlayer.framework
import SRGAnalytics_DataProvider        // For SRGAnalytics_DataProvider.framework
```

### Info.plist settings

The library automatically tracks which SRG SSR applications are installed on a user device, and sends this information to comScore. For this mechanism to work properly, though, your application **must** declare all official SRG SSR application URL schemes as being supported in its `Info.plist` file. This is achieved as follows:

* Open your application `Info.plist` file
* Add the `LSApplicationQueriesSchemes` key if it does not exist, and ensure that the associated array of values **is a superset of all URL schemes** found at the [following URL](http://pastebin.com/raw/RnZYEWCA). The schemes themselves must be extracted from all `ios` dictionary keys (e.g. `playrts`, `srfplayer`)

If this setup is not done appropriately, application installations will be reported incorrectly to comScore, and an error message will be logged. This situation is not catastropic but should be fixed when possible to ensure accurate measurements.

Since the list available from the above URL might change from time to time, the warning might resurface later to remind you to update your `Info.plist` file accordingly. Be sure to check your application logs (see `Logging` below).

### Working with the library

To learn about how the library can be used, have a look at the [getting started guide](Documentation/Getting-started.md).

### Logging

The library internally uses the [SRG Logger](https://github.com/SRGSSR/srglogger-ios) library for logging, within the `ch.srgssr.analytics` subsystem. This logger either automatically integrates with your own logger, or can be easily integrated with it. Refer to the SRG Logger documentation for more information.

## Demo project

To test what the library is capable of, try running the associated demo by opening the workspace and building the associated scheme.

## Migration from versions 1.x

For information about changes introduced with version 2 of the library, please read the [migration guide](Documentation/Migration-guide.md).

## License

See the [LICENSE](LICENSE) file for more information.