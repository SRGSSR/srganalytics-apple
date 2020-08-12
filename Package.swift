// swift-tools-version:5.3

import PackageDescription

struct ProjectSettings {
    static let marketingVersion: String = "4.2.4"
}

let package = Package(
    name: "SRGAnalytics",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v9),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "SRGAnalytics",
            targets: ["SRGAnalytics"]
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
        .package(name: "ComScore", url: "https://github.com/SRGSSR/ComScore-xcframework-apple.git", .exact("6.5.0")),
        .package(name: "SRGContentProtection", url: "https://github.com/SRGSSR/srgcontentprotection-apple.git", .branch("feature/spm-support")),
        .package(name: "SRGDataProvider", url: "https://github.com/SRGSSR/srgdataprovider-apple.git", .branch("feature/spm-support")),
        .package(name: "SRGIdentity", url: "https://github.com/SRGSSR/srgidentity-apple.git", .branch("feature/spm-support")),
        .package(name: "SRGLogger", url: "https://github.com/SRGSSR/srglogger-apple.git", .branch("feature/spm-support")),
        .package(name: "SRGMediaPlayer", url: "https://github.com/SRGSSR/srgmediaplayer-apple.git", .branch("feature/spm-support")),
        .package(name: "TCCore", url: "https://github.com/SRGSSR/TCCore-xcframework-apple.git", .exact("4.5.4-srg3")),
        .package(name: "TCSDK", url: "https://github.com/SRGSSR/TCSDK-xcframework-apple.git", .exact("4.4.1-srg3"))
    ],
    targets: [
        .target(
            name: "SRGAnalytics",
            dependencies: ["ComScore", "SRGLogger", "TCCore", "TCSDK"],
            cSettings: [
                .define("MARKETING_VERSION", to: "\"\(ProjectSettings.marketingVersion)\""),
            ]
        ),
        .target(
            name: "SRGAnalyticsMediaPlayer",
            dependencies: ["SRGAnalytics", "SRGMediaPlayer"],
            cSettings: [
                .headerSearchPath("Private")
            ]
        ),
        .target(
            name: "SRGAnalyticsDataProvider",
            dependencies: [
                "SRGAnalyticsMediaPlayer",
                "SRGContentProtection",
                .product(name: "SRGDataProviderNetwork", package: "SRGDataProvider")
            ]
        ),
        .target(
            name: "SRGAnalyticsIdentity",
            dependencies: ["SRGAnalytics", "SRGIdentity"],
            cSettings: [
                .headerSearchPath("Private")
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
