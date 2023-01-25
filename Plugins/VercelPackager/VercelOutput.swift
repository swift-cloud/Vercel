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

    public var fs: FileManager {
        FileManager.default
    }

    public var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    public init(packageManager: PackagePlugin.PackageManager, context: PackagePlugin.PluginContext, arguments: [String]) {
        self.packageManager = packageManager
        self.context = context
        self.arguments = arguments
    }

    public func prepare() async throws {
        try createDirectoryStructure()
        try copyStaticContent()
        try writeProjectConfiguration()
        try writeOutputConfiguration()
        try writeFunctionConfigurations()
    }

    public func build() async throws {
        for product in deployableProducts {
            let artifactPath = try await buildProduct(product)
            let bootstrapPath = vercelFunctionDirectory(product).appending("bootstrap")
            try fs.copyItem(atPath: artifactPath.string, toPath: bootstrapPath.string)
        }
    }

    public func deploy() async throws {
        print("")
        print("-------------------------------------------------------------------------")
        print("Deploying to Vercel: \"\(product.name)\"")
        print("-------------------------------------------------------------------------")
        print("")

        var deployArguments = [
            "deploy",
            "--prebuilt"
        ]

        if arguments.contains("--prod") {
            deployArguments.append("--prod")
        }

        if let token = vercelToken {
            deployArguments.append("--token")
            deployArguments.append(token)
        }

        try await Shell.execute(
            executable: context.tool(named: "vercel").path,
            arguments: deployArguments
        )
    }

    public func dev() async throws {
        Task.detached {
            try await Shell.execute(
                executable: context.tool(named: "swift").path,
                arguments: ["run", "--product", product.name],
                environment: ["LOCAL_LAMBDA_SERVER_ENABLED": "true"]
            )
        }

        Task.detached {
            try await Shell.execute(
                executable: context.tool(named: "node").path,
                arguments: [
                    projectDirectory.appending([".build", "checkouts", "Vercel", "server.js"]).string
                ]
            )
        }
        try await Task.sleep(nanoseconds: .max)
    }
}

// MARK: - Arguments

extension VercelOutput {

    public var product: Product {
        if let name = argument("product") {
            return deployableProducts.first { $0.name == name }!
        }
        return deployableProducts[0]
    }

    public var isDev: Bool {
        arguments.contains("dev")
    }

    public var isDeploy: Bool {
        arguments.contains("--deploy")
    }

    public var isProduction: Bool {
        arguments.contains("--prod")
    }

    public var functionMemory: String {
        argument("memory") ?? "512"
    }

    public var functionDuration: String {
        argument("duration") ?? "10"
    }

    public var functionRegions: String? {
        argument("regions")
    }

    public func argument(_ key: String) -> String? {
        guard let index = arguments.firstIndex(of: "--\(key)") else {
            return nil
        }
        return arguments[index + 1]
    }
}

// MARK: - Products

extension VercelOutput {

    public var deployableProducts: [Product] {
        context.package.products.filter { product in
            let target = product.targets.first(where: hasVercelDependency)
            return target != nil
        }
    }

    private func hasVercelDependency(_ target: Target) -> Bool {
        let dependency = target.dependencies.first { dep in
            switch dep {
            case .product(let product):
                return product.name.hasPrefix("Vercel")
            default:
                return false
            }
        }
        return dependency != nil
    }
}

// MARK: - .vercel

extension VercelOutput {

    public var projectDirectory: Path {
        context.package.directory
    }

    public var vercelDirectory: Path {
        projectDirectory.appending(".vercel")
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
        // Ensure we have a top level vercel directory
        try? fs.createDirectory(atPath: vercelDirectory.string, withIntermediateDirectories: true)
        // Clean the vercel output directory
        try? fs.removeItem(atPath: vercelOutputDirectory.string)
        // Create new directories
        try fs.createDirectory(atPath: vercelOutputDirectory.string, withIntermediateDirectories: true)
        try fs.createDirectory(atPath: vercelFunctionsDirectory.string, withIntermediateDirectories: true)
        // Create directories for each product
        for product in deployableProducts {
            try fs.createDirectory(atPath: vercelFunctionDirectory(product).string, withIntermediateDirectories: true)
        }
    }
}

// MARK: - static

extension VercelOutput {

    public var projectPublicDirectory: Path {
        projectDirectory.appending("public")
    }

    public var vercelStaticDirectory: Path {
        vercelOutputDirectory.appending("static")
    }

    public func copyStaticContent() throws {
        guard fs.fileExists(atPath: projectPublicDirectory.string) else {
            return
        }
        try fs.copyItem(atPath: projectPublicDirectory.string, toPath: vercelStaticDirectory.string)
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
        guard localProjectConfiguration() == nil else {
            return
        }
        let config = ProjectConfiguration(orgId: vercelOrgID, projectId: vercelProjectID)
        let data = try encoder.encode(config)
        fs.createFile(atPath: vercelProjectConfigurationPath.string, contents: data)
    }

    public func localProjectConfiguration() -> ProjectConfiguration? {
        guard let data = fs.contents(atPath: vercelProjectConfigurationPath.string) else {
            return nil
        }
        guard let config = try? JSONDecoder().decode(ProjectConfiguration.self, from: data) else {
            return nil
        }
        return config
    }
}

// MARK: - config.json

extension VercelOutput {

    public struct OutputConfiguration: Codable {
        public struct Route: Codable {
            public var src: String? = nil
            public var dest: String? = nil
            public var headers: [String: String]? = nil
            public var methods: [String]? = nil
            public var `continue`: Bool? = nil
            public var caseSensitive: Bool? = nil
            public var check: Bool? = nil
            public var status: Int? = nil
            public var handle: String? = nil
        }
        public var version: Int = 3
        public var routes: [Route]
    }

    public var vercelOutputConfigurationPath: Path {
        vercelOutputDirectory.appending("config.json")
    }

    public func writeOutputConfiguration() throws {
        let routes: [OutputConfiguration.Route] = [
            // Remove trailing slash
            .init(src: "^/(.*)/$", headers: ["Location": "/$1"], status: 308),
            // Handle filesystem
            .init(handle: "filesystem"),
            // Proxy all other routes
            .init(src: "^(?:/(.*))$", dest: product.name, check: true)
        ]
        let config = OutputConfiguration(routes: routes)
        let data = try encoder.encode(config)
        fs.createFile(atPath: vercelOutputConfigurationPath.string, contents: data)
    }
}

// MARK: - .vc-config.json

extension VercelOutput {

    public struct FunctionConfiguration: Codable {
        public var runtime: String = "provided.al2"
        public var handler: String = "bootstrap"
        public var memory: Int? = nil
        public var maxDuration: Int? = nil
        public var regions: [String]? = nil
        public var supportsWrapper: Bool = false
    }

    public func vercelFunctionConfigurationPath(_ product: Product) -> Path {
        vercelFunctionDirectory(product).appending(".vc-config.json")
    }

    public func writeFunctionConfigurations() throws {
        for product in deployableProducts {
            let config = FunctionConfiguration(
                memory: .init(functionMemory),
                maxDuration: .init(functionDuration),
                regions: functionRegions?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            )
            let data = try encoder.encode(config)
            fs.createFile(atPath: vercelFunctionConfigurationPath(product).string, contents: data)
        }
    }
}

// MARK: - Environment

extension VercelOutput {

    public var vercelOrgID: String {
        guard let value = ProcessInfo.processInfo.environment["VERCEL_ORG_ID"] else {
            fatalError("Missing VERCEL_ORG_ID")
        }
        return value
    }

    public var vercelProjectID: String {
        guard let value = ProcessInfo.processInfo.environment["VERCEL_PROJECT_ID"] else {
            fatalError("Missing VERCEL_PROJECT_ID")
        }
        return value
    }

    public var vercelToken: String? {
        return ProcessInfo.processInfo.environment["VERCEL_TOKEN"]
    }
}

// MARK: - Build

extension VercelOutput {

    public func buildProduct(_ product: Product) async throws -> Path {
        print("")
        print("-------------------------------------------------------------------------")
        print("Building product: \"\(product.name)\"")
        print("-------------------------------------------------------------------------")
        print("")

        if isDeploy, Utils.isAmazonLinux == false {
            return try await buildDockerProduct(product)
        } else {
            return try await buildNativeProduct(product)
        }
    }

    private func buildNativeProduct(_ product: Product) async throws -> Path {
        var parameters = PackageManager.BuildParameters()
        parameters.configuration = .release
        parameters.otherSwiftcFlags = Utils.isAmazonLinux ? ["-static-stdlib"] : []
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

    private func buildDockerProduct(_ product: Product) async throws -> Path {
        let dockerToolPath = try context.tool(named: "docker").path
        let baseImage = "swift:5.7-amazonlinux2"

        // update the underlying docker image, if necessary
        print("updating \"\(baseImage)\" docker image")
        try await Shell.execute(
            executable: dockerToolPath,
            arguments: ["pull", baseImage],
            logLevel: .output
        )

        // get the build output path
        let buildOutputPathCommand = "swift build -c release --show-bin-path"
        let dockerBuildOutputPath = try await Shell.execute(
            executable: dockerToolPath,
            arguments: [
                "run",
                "--platform", "linux/x86_64",
                "--rm",
                "-v", "\(context.package.directory.string):/workspace",
                "-w", "/workspace",
                baseImage,
                "bash", "-cl", buildOutputPathCommand
            ],
            logLevel: .output
        )
        guard let buildPathOutput = dockerBuildOutputPath.split(separator: "\n").last else {
            throw BuildError.failedParsingDockerOutput(dockerBuildOutputPath)
        }
        let buildOutputPath = Path(buildPathOutput.replacingOccurrences(of: "/workspace", with: context.package.directory.string))

        // build the product
        let buildCommand = "swift build -c release --product \(product.name) --static-swift-stdlib"
        try await Shell.execute(
            executable: dockerToolPath,
            arguments: [
                "run",
                "--platform", "linux/x86_64",
                "--rm",
                "-v", "\(context.package.directory.string):/workspace",
                "-w", "/workspace",
                baseImage,
                "bash", "-cl", buildCommand
            ],
            logLevel: .output
        )

        // ensure the final binary built correctly
        let productPath = buildOutputPath.appending(product.name)
        guard fs.fileExists(atPath: productPath.string) else {
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
