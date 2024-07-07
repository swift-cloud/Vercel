// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "swift-vercel",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "Vercel", targets: ["Vercel"]),
        .library(name: "VercelVapor", targets: ["VercelVapor"]),
        .plugin(name: "VercelPackager", targets: ["VercelPackager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime", from: "1.0.0-alpha.2"),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "Vercel",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "VercelVapor",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "Vapor", package: "vapor"),
                .byName(name: "Vercel"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .plugin(
            name: "VercelPackager",
            capability: .command(
                intent: .custom(
                    verb: "vercel", description: "Build and deploy your Swift application to Vercel"
                )
            )
        ),
        .testTarget(
            name: "VercelTests",
            dependencies: [
                .byName(name: "Vercel")
            ]
        ),
    ]
)
