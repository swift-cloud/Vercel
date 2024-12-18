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

    public init(packageManager: PackagePlugin.PackageManager, context: PackagePlugin.PluginContext, arguments: [String])
    {
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
        let artifactPath = try await buildProduct(product)
        let bootstrapPath = vercelFunctionDirectory(product).appending("bootstrap")
        try fs.copyItem(atPath: artifactPath.string, toPath: bootstrapPath.string)
    }

    public func deploy() async throws {
        print("")
        print("-------------------------------------------------------------------------")
        print("Deploying to Vercel: \"\(product.name)\"")
        print("-------------------------------------------------------------------------")
        print("")

        var deployArguments = [
            "deploy",
            "--prebuilt",
        ]

        if arguments.contains("--prod") {
            deployArguments.append("--prod")
        }

        if let token = vercelToken {
            deployArguments.append("--token")
            deployArguments.append(token)
        }

        try Shell.execute(
            executable: context.tool(named: "vercel").path,
            arguments: deployArguments
        )
    }

    public func dev() async throws {
        print("")
        print("-------------------------------------------------------------------------")
        print("Building application")
        print("-------------------------------------------------------------------------")
        print("")

        try Shell.execute(
            executable: context.tool(named: "swift").path,
            arguments: ["build", "--package-path", projectDirectory.string]
        )

        Task {
            try startSwiftAppServer()
        }

        Task {
            try startNodeProxyServer()
        }

        try await Task.sleep(nanoseconds: 3_000_000_000)

        print("")
        print("-------------------------------------------------------------------------")
        print("Running dev server: http://localhost:\(port)")
        print("-------------------------------------------------------------------------")
        print("")

        while true {
            try await Task.sleep(nanoseconds: 1_000_000_000_000)
        }
    }

    public func proxyServer() async throws {
        print("")
        print("-------------------------------------------------------------------------")
        print("Running dev server: http://localhost:\(port)")
        print("-------------------------------------------------------------------------")
        print("")
        print("")
        print("Reminder: In Xcode set the Run environment variable LOCAL_LAMBDA_SERVER_ENABLED=true")
        print("")
        print("")

        try startNodeProxyServer()
    }
}

// MARK: - Arguments

extension VercelOutput {

    public var product: Product {
        if let name = argument("product") {
            return context.package.products.first { $0.name == name }!
        }
        return deployableProducts[0]
    }

    public var isDev: Bool {
        arguments.contains("dev") || arguments.contains("--dev")
    }

    public var isServer: Bool {
        arguments.contains("server") || arguments.contains("--server")
    }

    public var isDeploy: Bool {
        arguments.contains("deploy") || arguments.contains("--deploy")
    }

    public var isProduction: Bool {
        arguments.contains("--prod")
    }

    public var nightly: Bool {
        arguments.contains("--nightly")
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

    public var port: String {
        argument("port") ?? "7676"
    }

    public var architecture: Architecture {
        if let value = argument("arch"), let arch = Architecture(rawValue: value) {
            return arch
        }
        return Utils.currentArchitecture ?? .x86
    }

    public func argument(_ key: String) -> String? {
        guard let index = arguments.firstIndex(of: "--\(key)") else {
            return nil
        }
        return arguments[index + 1]
    }

    public func localEnvironment() -> [String: String] {
        // Lookup local .env file
        guard let data = fs.contents(atPath: projectDirectory.appending(".env").string) else {
            return [:]
        }

        // Convert data to string
        guard let text = String(data: data, encoding: .utf8) else {
            return [:]
        }

        // Split file into lines
        let lines =
            text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        return lines.reduce(into: [:]) { env, line in
            // Ensure its not a comment
            guard !line.starts(with: "#") else { return }

            // Split the line into key value parts
            let keyValue =
                line
                .split(separator: "=", maxSplits: 1)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            // Ensure exactly two parts
            guard keyValue.count == 2 else { return }

            // Validate key
            guard !keyValue[0].isEmpty else { return }

            // Validate value
            guard keyValue[1].count >= 2, keyValue[1].hasPrefix("\""), keyValue[1].hasSuffix("\"") else { return }

            // Get key and value
            let key = String(keyValue[0])
            let value = String(keyValue[1].dropFirst().dropLast())

            // Set the key and value
            env[key] = value
        }
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
        try fs.createDirectory(atPath: vercelFunctionDirectory(product).string, withIntermediateDirectories: true)
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
        public struct Cron: Codable {
            public var path: String
            public var schedule: String
        }
        public struct Override: Codable {
            public var path: String? = nil
            public var contentType: String? = nil
        }
        public struct Framework: Codable {
            public var version: String
        }
        public var version: Int = 3
        public var routes: [Route] = []
        public var crons: [Cron] = []
        public var overrides: [String: Override] = [:]
        public var cache: [String] = []
        public var framework: Framework
    }

    public var vercelOutputConfigurationPath: Path {
        vercelOutputDirectory.appending("config.json")
    }

    public func writeOutputConfiguration() throws {
        let vercel = vercelConfiguration()
        let routes: [OutputConfiguration.Route] = [
            // Remove trailing slash
            .init(src: "^(?:/((?:[^/]+?)(?:/(?:[^/]+?))*))/$", headers: ["Location": "/$1"], status: 308),
            // Handle filesystem
            .init(handle: "filesystem"),
            // Proxy all other routes
            .init(src: "^.*$", dest: product.name, check: true),
        ]
        let config = OutputConfiguration(
            routes: routes,
            crons: vercel?.crons ?? [],
            cache: [".build/**"],
            framework: .init(version: context.package.toolsVersion.versionString)
        )
        let data = try encoder.encode(config)
        fs.createFile(atPath: vercelOutputConfigurationPath.string, contents: data)
    }
}

// MARK: - vercel.json

extension VercelOutput {

    public struct VercelConfiguration: Codable {
        public var crons: [OutputConfiguration.Cron]? = nil
    }

    public var vercelConfigurationPath: Path {
        projectDirectory.appending("vercel.json")
    }

    public func vercelConfiguration() -> VercelConfiguration? {
        guard let data = fs.contents(atPath: vercelConfigurationPath.string) else {
            return nil
        }
        guard let config = try? JSONDecoder().decode(VercelConfiguration.self, from: data) else {
            return nil
        }
        return config
    }
}

// MARK: - .vc-config.json

extension VercelOutput {

    public struct FunctionConfiguration: Codable {
        public var runtime: String = "provided.al2023"
        public var handler: String = "bootstrap"
        public var architecture: Architecture? = nil
        public var memory: Int? = nil
        public var maxDuration: Int? = nil
        public var regions: [String]? = nil
        public var supportsWrapper: Bool = false
    }

    public func vercelFunctionConfigurationPath(_ product: Product) -> Path {
        vercelFunctionDirectory(product).appending(".vc-config.json")
    }

    public func writeFunctionConfigurations() throws {
        let config = FunctionConfiguration(
            architecture: architecture,
            memory: .init(functionMemory),
            maxDuration: .init(functionDuration),
            regions: functionRegions?.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        )
        let data = try encoder.encode(config)
        fs.createFile(atPath: vercelFunctionConfigurationPath(product).string, contents: data)
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

// MARK: - Server

extension VercelOutput {

    public func startSwiftAppServer() throws {
        var env = localEnvironment()
        env["LOCAL_LAMBDA_SERVER_ENABLED"] = "true"

        try Shell.execute(
            executable: context.tool(named: "swift").path,
            arguments: ["run", "--package-path", projectDirectory.string],
            environment: env
        )
    }

    public func startNodeProxyServer() throws {
        try Shell.execute(
            executable: context.tool(named: "node").path,
            arguments: [
                projectDirectory.appending([
                    ".build", "checkouts", "Vercel", "Plugins", "VercelPackager", "Server", "server.cjs",
                ]).string,
                port,
            ],
            environment: ["SWIFT_PROJECT_DIRECTORY": projectDirectory.string],
            printCommand: false
        )
    }
}

// MARK: - Build

extension VercelOutput {

    public var swiftBuildDirectory: Path {
        projectDirectory.appending(".build")
    }

    public var swiftBuildReleaseDirectory: Path {
        swiftBuildDirectory.appending("release")
    }

    public func buildProduct(_ product: Product) async throws -> Path {
        print("")
        print("-------------------------------------------------------------------------")
        print("Building product: \"\(product.name)\"")
        print("-------------------------------------------------------------------------")

        if isDeploy, Utils.isAmazonLinux == false {
            return try await buildDockerProduct(product)
        } else {
            return try await buildNativeProduct(product)
        }
    }

    private func buildNativeProduct(_ product: Product) async throws -> Path {
        var parameters = PackageManager.BuildParameters()
        parameters.configuration = .release
        parameters.otherLinkerFlags = ["-S"]
        parameters.otherSwiftcFlags = Utils.isAmazonLinux ? ["-static-stdlib", "-Osize"] : ["-Osize"]
        parameters.logging = .concise

        let result = try packageManager.build(
            .product(product.name),
            parameters: parameters
        )

        print("")
        print(result.logText)
        print("")

        guard let artifact = result.executableArtifact(for: product) else {
            throw BuildError.productExecutableNotFound(product.name)
        }

        return artifact.path
    }

    private func buildDockerProduct(_ product: Product) async throws -> Path {
        let dockerToolPath = try context.tool(named: "docker").path
        let baseImage = nightly
            ? "swiftlang/swift:nightly-\(context.package.toolsVersion.major).\(context.package.toolsVersion.minor)-amazonlinux2"
            : "swift:\(context.package.toolsVersion.major).\(context.package.toolsVersion.minor)-amazonlinux2"

        let cleanCommand = arguments.contains("--clean")
        ? "rm -rf .build && rm -rf ~/.swift/pm && "
        : ""

        let buildCommand = "swift build -c release -Xswiftc -Osize -Xlinker -S --product \(product.name) --static-swift-stdlib"
        let buildOutputPathCommand = "\(cleanCommand)\(buildCommand) --show-bin-path"

        let workspacePathPrefix = arguments.contains("--parent")
        ? context.package.directory.removingLastComponent()
        : context.package.directory

        let lastPathComponent = arguments.contains("--parent")
        ? context.package.directory.lastComponent
        : ""

        let dockerWorkspacePath = "/workspace/\(lastPathComponent)"

        // get the build output path
        let dockerBuildOutputPath = try Shell.execute(
            executable: dockerToolPath,
            arguments: [
                "run",
                "--platform", "linux/\(architecture.rawValue)",
                "--rm",
                "-v", "\(workspacePathPrefix):/workspace",
                "-w", dockerWorkspacePath,
                baseImage,
                "bash", "-cl", "pwd && \(buildOutputPathCommand)"
            ]
        )

        guard let buildPathOutput = dockerBuildOutputPath.split(separator: "\n").last else {
            throw BuildError.failedParsingDockerOutput(dockerBuildOutputPath)
        }

        let productPath = Path(buildPathOutput.replacingOccurrences(of: dockerWorkspacePath, with: context.package.directory.string))

        // build the product
        try Shell.execute(
            executable: dockerToolPath,
            arguments: [
                "run",
                "--platform", "linux/\(architecture.rawValue)",
                "--rm",
                "-v", "\(workspacePathPrefix):/workspace",
                "-w", dockerWorkspacePath,
                baseImage,
                "bash", "-cl", "swift build -c release -Xswiftc -Osize --static-swift-stdlib",
            ]
        )

        // ensure the final binary built correctly
        let productPathFinal = swiftBuildReleaseDirectory.appending(product.name)
        guard fs.fileExists(atPath: productPathFinal.string) else {
            Diagnostics.error("expected '\(product.name)' binary at \"\(productPath.string)\"")
            throw BuildError.productExecutableNotFound(product.name)
        }

        // strip the binary
        let stripCommand = "ls -la .build/release/\(product.name) && strip .build/release/\(product.name) && ls -la .build/release/\(product.name)"
        try Shell.execute(
            executable: dockerToolPath,
            arguments: [
                "run",
                "--platform", "linux/\(architecture.rawValue)",
                "--rm",
                "-v", "\(workspacePathPrefix):/workspace",
                "-w", dockerWorkspacePath,
                baseImage,
                "bash", "-cl", stripCommand
            ]
        )

        return productPathFinal
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
