// swift-tools-version:5.3

import PackageDescription

struct ProjectSettings {
    static let marketingVersion: String = "8.2.1"
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
        .package(name: "ComScore", url: "https://github.com/comScore/Comscore-Swift-Package-Manager.git", .upToNextMinor(from: "6.10.0")),
        .package(name: "SRGContentProtection", url: "https://github.com/SRGSSR/srgcontentprotection-apple.git", .upToNextMinor(from: "3.1.0")),
        .package(name: "SRGDataProvider", url: "https://github.com/SRGSSR/srgdataprovider-apple.git", .upToNextMinor(from: "18.0.0")),
        .package(name: "SRGIdentity", url: "https://github.com/SRGSSR/srgidentity-apple.git", .upToNextMinor(from: "3.3.0")),
        .package(name: "SRGLogger", url: "https://github.com/SRGSSR/srglogger-apple.git", .upToNextMinor(from: "3.1.0")),
        .package(name: "SRGMediaPlayer", url: "https://github.com/SRGSSR/srgmediaplayer-apple.git", .upToNextMinor(from: "7.2.0")),
        .package(name: "TCCore", url: "https://github.com/SRGSSR/TCCore-xcframework-apple.git", .upToNextMinor(from: "5.1.1")),
        .package(name: "TCServerSide", url: "https://github.com/SRGSSR/TCServerSide-xcframework-apple.git", .upToNextMinor(from: "5.1.2"))
    ],
    targets: [
        .target(
            name: "SRGAnalytics",
            dependencies: ["ComScore", "SRGLogger", "TCCore", "TCServerSide"],
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
