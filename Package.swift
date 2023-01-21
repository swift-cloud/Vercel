// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Vercel",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "Vercel", targets: ["Vercel"]),
        .plugin(name: "VercelPackager", targets: ["VercelPackager"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", branch: "main"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", branch: "main")
    ],
    targets: [
        .target(name: "Vercel", dependencies: [
            .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
            .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events")
        ]),
        .plugin(name: "VercelPackager", capability: .command(
            intent: .custom(
                verb: "vercel",
                description: "Archive the Swift binary and package for Vercel."
            )
        )),
        .testTarget(name: "VercelTests", dependencies: [
            .byName(name: "Vercel")
        ])
    ]
)
