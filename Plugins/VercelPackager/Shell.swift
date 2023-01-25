//
//  Shell.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import Dispatch
import Foundation
import PackagePlugin

#if canImport(Glibc)
import Glibc
#endif

public struct Shell {

    @discardableResult
    public static func execute(
        executable: Path,
        arguments: [String],
        environment: [String: String] = [:],
        customWorkingDirectory: Path? = .none,
        logLevel: ProcessLogLevel = .output
    ) async throws -> String {
        if logLevel >= .debug {
            print("\(executable.string) \(arguments.joined(separator: " "))")
        }

        var output = ""

        let outputHandler = { (data: Data?) in
            guard let _output = data.flatMap({ String(data: $0, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(["\n"])) }), !_output.isEmpty else {
                return
            }

            output += _output + "\n"

            switch logLevel {
            case .silent:
                break
            case .debug(let outputIndent), .output(let outputIndent):
                print(String(repeating: " ", count: outputIndent), terminator: "")
                print(_output)
                fflush(stdout)
            }
        }

        let pipe = Pipe()
        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            outputHandler(fileHandle.availableData)
        }

        let process = Process()
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: executable.string)
        process.arguments = arguments
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { $1 }
        if let workingDirectory = customWorkingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory.string)
        }
        process.terminationHandler = { _ in
            outputHandler(try? pipe.fileHandleForReading.readToEnd())
        }

        try process.run()

        while process.isRunning {
            guard Task.isCancelled == false else {
                process.terminate()
                break
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        if process.terminationStatus != 0 {
            // print output on failure and if not already printed
            if logLevel < .output {
                print(output)
                fflush(stdout)
            }
            throw ShellError.processFailed([executable.string] + arguments, process.terminationStatus)
        }

        return output
    }
}

public enum ProcessLogLevel: Comparable {
    case silent
    case output(outputIndent: Int)
    case debug(outputIndent: Int)

    var naturalOrder: Int {
        switch self {
        case .silent:
            return 0
        case .output:
            return 1
        case .debug:
            return 2
        }
    }

    static public var output: Self {
        .output(outputIndent: 2)
    }

    static public var debug: Self {
        .debug(outputIndent: 2)
    }

    static public func < (lhs: ProcessLogLevel, rhs: ProcessLogLevel) -> Bool {
        lhs.naturalOrder < rhs.naturalOrder
    }
}

public enum ShellError: Error, CustomStringConvertible {
    case processFailed([String], Int32)

    public var description: String {
        switch self {
        case .processFailed(let arguments, let code):
            return "\(arguments.joined(separator: " ")) failed with code \(code)"
        }
    }
}
