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
        customWorkingDirectory: Path? = .none
    ) throws -> String {
        // Create our process and setup arguments and environment
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable.string)
        process.arguments = arguments
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { $1 }

        // Setup custom working directory
        if let workingDirectory = customWorkingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory.string)
        }

        // Because FileHandle's readabilityHandler might be called from a
        // different queue from the calling queue, avoid a data race by
        // protecting reads and writes to outputData and errorData on
        // a single dispatch queue.
        let outputQueue = DispatchQueue(label: "bash-output-queue")

        var outputData = Data()
        var errorData = Data()

        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        let errorPipe = Pipe()
        process.standardError = errorPipe

        #if !os(Linux)
        outputPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            outputQueue.async {
                outputData.append(data)
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            outputQueue.async {
                errorData.append(data)
            }
        }
        #endif

        // Run our process
        process.launch()

        #if os(Linux)
        outputQueue.sync {
            outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        }
        #endif

        process.waitUntilExit()

        #if !os(Linux)
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        #endif

        // Block until all writes have occurred to outputData and errorData,
        // and then read the data back out.
        return try outputQueue.sync {
            if process.terminationStatus != 0 {
                throw ShellError.processFailed(arguments, process.terminationStatus)
            }

            return String(data: outputData, encoding: .utf8)!
        }
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
