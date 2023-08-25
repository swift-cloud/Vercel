// swift-tools-version: 5.6

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
        .library(name: "VercelVapor", targets: ["VercelVapor"]),
        .plugin(name: "VercelPackager", targets: ["VercelPackager"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto", "1.0.0" ..< "3.0.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime", from: "1.0.0-alpha.1"),
        .package(url: "https://github.com/vapor/vapor", from: "4.0.0")
    ],
    targets: [
        .target(name: "Vercel", dependencies: [
            .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
            .product(name: "Crypto", package: "swift-crypto")
        ]),
        .target(name: "VercelVapor", dependencies: [
            .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
            .product(name: "Vapor", package: "vapor"),
            .byName(name: "Vercel")
        ]),
        .plugin(
            name: "VercelPackager",
            capability: .command(
                intent: .custom(verb: "vercel", description: "Build and deploy your Swift application to Vercel")
            )
        ),
        .testTarget(name: "VercelTests", dependencies: [
            .byName(name: "Vercel")
        ])
    ]
)
