// swift-tools-version:5.3

import PackageDescription

struct ProjectSettings {
    static let marketingVersion: String = "9.1.7"
}

let package = Package(
    name: "SRGAnalytics",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "SRGAnalytics",
            targets: ["SRGAnalytics"]
        ),
        .library(
            name: "SRGAnalyticsSwiftUI",
            targets: ["SRGAnalyticsSwiftUI"]
        ),
        .library(
            name: "SRGAnalyticsMediaPlayer",
            targets: ["SRGAnalyticsMediaPlayer"]
        ),
        .library(
            name: "SRGAnalyticsDataProvider",
            targets: ["SRGAnalyticsDataProvider"]
        ),
        .library(
            name: "SRGAnalyticsIdentity",
            targets: ["SRGAnalyticsIdentity"]
        )
    ],
    dependencies: [
        .package(name: "ComScore", url: "https://github.com/comScore/Comscore-Swift-Package-Manager.git", .upToNextMinor(from: "6.13.0")),
        .package(name: "SRGContentProtection", url: "https://github.com/SRGSSR/srgcontentprotection-apple.git", .upToNextMinor(from: "3.1.0")),
        .package(name: "SRGDataProvider", url: "https://github.com/SRGSSR/srgdataprovider-apple.git", .upToNextMinor(from: "19.0.0")),
        .package(name: "SRGIdentity", url: "https://github.com/SRGSSR/srgidentity-apple.git", .upToNextMinor(from: "3.3.0")),
        .package(name: "SRGLogger", url: "https://github.com/SRGSSR/srglogger-apple.git", .upToNextMinor(from: "3.1.0")),
        .package(name: "SRGMediaPlayer", url: "https://github.com/SRGSSR/srgmediaplayer-apple.git", .upToNextMinor(from: "7.2.0")),
        .package(name: "TagCommander", url: "https://github.com/CommandersAct/iOSV5.git", .upToNextMinor(from: "5.4.9"))
    ],
    targets: [
        .target(
            name: "SRGAnalytics",
            dependencies: [
                "ComScore",
                "SRGLogger",
                .product(name: "TCCore", package: "TagCommander"),
                .product(name: "TCServerSide_noIDFA", package: "TagCommander")
            ],
            cSettings: [
                .define("MARKETING_VERSION", to: "\"\(ProjectSettings.marketingVersion)\""),
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release))
            ]
        ),
        .target(
            name: "SRGAnalyticsSwiftUI",
            dependencies: ["SRGAnalytics"]
        ),
        .target(
            name: "SRGAnalyticsMediaPlayer",
            dependencies: ["SRGAnalytics", "SRGMediaPlayer"],
            cSettings: [
                .headerSearchPath("Private"),
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release))
            ]
        ),
        .target(
            name: "SRGAnalyticsDataProvider",
            dependencies: [
                "SRGAnalyticsMediaPlayer",
                "SRGContentProtection",
                .product(name: "SRGDataProviderNetwork", package: "SRGDataProvider")
            ],
            cSettings: [
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release))
            ]
        ),
        .target(
            name: "SRGAnalyticsIdentity",
            dependencies: ["SRGAnalytics", "SRGIdentity"],
            cSettings: [
                .headerSearchPath("Private"),
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "SRGAnalyticsTests",
            dependencies: ["SRGAnalytics", "SRGAnalyticsMediaPlayer", "SRGAnalyticsDataProvider"],
            cSettings: [
                .headerSearchPath("Private")
            ]
        )
    ]
)
