// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Vercel",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "Vercel", targets: ["Vercel"]),
        .library(name: "VercelVapor", targets: ["VercelVapor"]),
        .plugin(name: "VercelPackager", targets: ["VercelPackager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto", from: "3.0.0"),
        .package(
            url: "https://github.com/swift-server/swift-aws-lambda-runtime", from: "1.0.0-alpha.2"),
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.20.1"),
        .package(url: "https://github.com/vapor/vapor", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "Vercel",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Crypto", package: "swift-crypto"),
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
