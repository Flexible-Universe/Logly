// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Logly",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "Logly",
            targets: ["Logly"]),
        .library(
            name: "LoglySentry",
            targets: ["LoglySentry"]),
    ],
    traits: [
        .trait(
            name: "Sentry",
            description: "Enables the LoglySentry Sentry backend and its sentry-cocoa dependency."),
    ],
    dependencies: [
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0"),
    ],
    targets: [
        .target(
            name: "Logly"),
        .target(
            name: "LoglySentry",
            dependencies: [
                "Logly",
                .product(name: "Sentry", package: "sentry-cocoa",
                         condition: .when(traits: ["Sentry"])),
            ]),
        .testTarget(
            name: "LoglyTests",
            dependencies: ["Logly"]
        ),
        .testTarget(
            name: "LoglySentryTests",
            dependencies: ["LoglySentry"]
        ),
    ]
)
