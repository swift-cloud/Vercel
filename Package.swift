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
        .package(url: "https://github.com/swift-cloud/Crypto", from: "1.6.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "1.0.0-alpha.1")
    ],
    targets: [
        .target(name: "Vercel", dependencies: [
            .byName(name: "Crypto"),
            .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime")
        ]),
        .plugin(name: "VercelPackager", capability: .command(
            intent: .custom(
                verb: "vercel",
                description: "Build and deploy your Swift application to Vercel"
            )
        )),
        .testTarget(name: "VercelTests", dependencies: [
            .byName(name: "Vercel")
        ])
    ]
)
