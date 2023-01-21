//
//  VercelOutput.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import Foundation
import PackagePlugin

public struct VercelOutput {

    public let packageManager: PackagePlugin.PackageManager

    public let context: PackagePlugin.PluginContext

    public let arguments: [String]

    public init(packageManager: PackagePlugin.PackageManager, context: PackagePlugin.PluginContext, arguments: [String]) {
        self.packageManager = packageManager
        self.context = context
        self.arguments = arguments
    }

    public func prepare() throws {
        try createDirectoryStructure()
        try writeProjectConfiguration()
        try writeOutputConfiguration()
        try writeFunctionConfigurations()
    }

    public func build() throws {
        for product in context.package.products {
            let artifactPath = try buildProduct(product)
            let bootstrapPath = vercelFunctionDirectory(product).appending("bootstrap")
            try FileManager.default.copyItem(atPath: artifactPath.string, toPath: bootstrapPath.string)
        }
    }

    public func deploy() throws {
        var deployArguments = [
            "--cwd", context.pluginWorkDirectory.string,
            "deploy",
            "--prebuilt",
            "--token", token
        ]
        if arguments.contains("--prod") {
            deployArguments.append("--prod")
        }

        try Shell.execute(
            executable: context.tool(named: "vercel").path,
            arguments: deployArguments
        )
    }
}

// MARK: - .vercel

extension VercelOutput {

    public var vercelDirectory: Path {
        context.pluginWorkDirectory.appending(".vercel")
    }

    public var vercelOutputDirectory: Path {
        vercelDirectory.appending("output")
    }

    public var vercelFunctionsDirectory: Path {
        vercelOutputDirectory.appending("functions")
    }

    public func vercelFunctionDirectory(_ product: Product) -> Path {
        vercelFunctionsDirectory.appending("\(product.name).func")
    }

    public func createDirectoryStructure() throws {
        // Clean the directory
        if FileManager.default.fileExists(atPath: vercelDirectory.string) {
            try FileManager.default.removeItem(atPath: vercelDirectory.string)
        }
        // Create new directories
        try FileManager.default.createDirectory(atPath: vercelDirectory.string, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: vercelOutputDirectory.string, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: vercelFunctionsDirectory.string, withIntermediateDirectories: true)
        // Create directories for each product
        for product in context.package.products {
            try FileManager.default.createDirectory(atPath: vercelFunctionDirectory(product).string, withIntermediateDirectories: true)
        }
    }
}

// MARK: - project.json

extension VercelOutput {

    public struct ProjectConfiguration: Codable {
        public var orgId: String
        public var projectId: String
    }

    public var vercelProjectConfigurationPath: Path {
        vercelDirectory.appending("project.json")
    }

    public func writeProjectConfiguration() throws {
        let config = ProjectConfiguration(orgId: orgId, projectId: projectId)
        let data = try JSONEncoder().encode(config)
        FileManager.default.createFile(atPath: vercelProjectConfigurationPath.string, contents: data)
    }
}

// MARK: - config.json

extension VercelOutput {

    public struct OutputConfiguration: Codable {
        public struct Route: Codable {
            public var src: String
            public var dest: String
        }
        public var version: Int = 3
        public var routes: [Route]
    }

    public var vercelOutputConfigurationPath: Path {
        vercelOutputDirectory.appending("config.json")
    }

    public func writeOutputConfiguration() throws {
        let config = OutputConfiguration(routes: [
            .init(src: "/(.*)", dest: context.package.products[0].name)
        ])
        let data = try JSONEncoder().encode(config)
        FileManager.default.createFile(atPath: vercelOutputConfigurationPath.string, contents: data)
    }
}

// MARK: - .vc-config.json

extension VercelOutput {

    public struct FunctionConfiguration: Codable {
        public var runtime: String = "provided.al2"
        public var handler: String = "bootstrap"
        public var supportsWrapper: Bool = false
    }

    public func vercelFunctionConfigurationPath(_ product: Product) -> Path {
        vercelFunctionDirectory(product).appending(".vc-config.json")
    }

    public func writeFunctionConfigurations() throws {
        for product in context.package.products {
            let config = FunctionConfiguration()
            let data = try JSONEncoder().encode(config)
            FileManager.default.createFile(atPath: vercelFunctionConfigurationPath(product).string, contents: data)
        }
    }
}

// MARK: - Environment

extension VercelOutput {

    public var orgId: String {
        guard let value = ProcessInfo.processInfo.environment["VERCEL_ORG_ID"] else {
            fatalError("Missing VERCEL_ORG_ID")
        }
        return value
    }

    public var projectId: String {
        guard let value = ProcessInfo.processInfo.environment["VERCEL_PROJECT_ID"] else {
            fatalError("Missing VERCEL_PROJECT_ID")
        }
        return value
    }

    public var token: String {
        guard let value = ProcessInfo.processInfo.environment["VERCEL_TOKEN"] else {
            fatalError("Missing VERCEL_TOKEN")
        }
        return value
    }
}

// MARK: - Build

extension VercelOutput {

    public func buildProduct(_ product: Product) throws -> Path {
        if Utils.isAmazonLinux {
            return try buildNativeProduct(product)
        } else {
            return try buildDockerProduct(product)
        }
    }

    private func buildNativeProduct(_ product: Product) throws -> Path {
        print("-------------------------------------------------------------------------")
        print("Building product: \"\(product.name)\"")
        print("-------------------------------------------------------------------------")

        var parameters = PackageManager.BuildParameters()
        parameters.configuration = .release
        parameters.otherSwiftcFlags = ["-static-stdlib"]
        parameters.logging = .concise

        let result = try packageManager.build(
            .product(product.name),
            parameters: parameters
        )

        guard let artifact = result.executableArtifact(for: product) else {
            throw BuildError.productExecutableNotFound(product.name)
        }

        return artifact.path
    }

    private func buildDockerProduct(_ product: Product) throws -> Path {
        let dockerToolPath = try context.tool(named: "docker").path
        let baseImage = "swift:5.7-amazonlinux2"

        print("-------------------------------------------------------------------------")
        print("Building product: \"\(product.name)\"")
        print("-------------------------------------------------------------------------")

        // update the underlying docker image, if necessary
        print("updating \"\(baseImage)\" docker image")
        try Shell.execute(
            executable: dockerToolPath,
            arguments: ["pull", baseImage],
            logLevel: .output
        )

        // get the build output path
        let buildOutputPathCommand = "swift build -c release --show-bin-path"
        let dockerBuildOutputPath = try Shell.execute(
            executable: dockerToolPath,
            arguments: ["run", "--rm", "-v", "\(context.package.directory.string):/workspace", "-w", "/workspace", baseImage, "bash", "-cl", buildOutputPathCommand],
            logLevel: .debug
        )
        guard let buildPathOutput = dockerBuildOutputPath.split(separator: "\n").last else {
            throw BuildError.failedParsingDockerOutput(dockerBuildOutputPath)
        }
        let buildOutputPath = Path(buildPathOutput.replacingOccurrences(of: "/workspace", with: context.package.directory.string))
        let buildCommand = "swift build -c release --product \(product.name) --static-swift-stdlib"
        try Shell.execute(
            executable: dockerToolPath,
            arguments: ["run", "--platform", "linux/x86_64", "--rm", "-v", "\(context.package.directory.string):/workspace", "-w", "/workspace", baseImage, "bash", "-cl", buildCommand],
            logLevel: .debug
        )
        let productPath = buildOutputPath.appending(product.name)
        guard FileManager.default.fileExists(atPath: productPath.string) else {
            Diagnostics.error("expected '\(product.name)' binary at \"\(productPath.string)\"")
            throw BuildError.productExecutableNotFound(product.name)
        }
        return productPath
    }
}

public enum BuildError: Error, CustomStringConvertible {
    case invalidArgument(String)
    case unsupportedPlatform(String)
    case unknownProduct(String)
    case productExecutableNotFound(String)
    case failedWritingDockerfile
    case failedParsingDockerOutput(String)
    case processFailed([String], Int32)

    public var description: String {
        switch self {
        case .invalidArgument(let description):
            return description
        case .unsupportedPlatform(let description):
            return description
        case .unknownProduct(let description):
            return description
        case .productExecutableNotFound(let product):
            return "product executable not found '\(product)'"
        case .failedWritingDockerfile:
            return "failed writing dockerfile"
        case .failedParsingDockerOutput(let output):
            return "failed parsing docker output: '\(output)'"
        case .processFailed(let arguments, let code):
            return "\(arguments.joined(separator: " ")) failed with code \(code)"
        }
    }
}

extension PackageManager.BuildResult {

    // Find the executable produced by the build
    public func executableArtifact(for product: Product) -> PackageManager.BuildResult.BuiltArtifact? {
        let executables = self.builtArtifacts.filter { $0.kind == .executable && $0.path.lastComponent == product.name }
        guard !executables.isEmpty else {
            return nil
        }
        guard executables.count == 1, let executable = executables.first else {
            return nil
        }
        return executable
    }
}