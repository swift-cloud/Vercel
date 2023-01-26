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
        print("")
        print("\(executable.string) \(arguments.joined(separator: " "))")
        print("")

        var output = ""
        let outputSync = DispatchGroup()
        let outputQueue = DispatchQueue(label: "VercelPackager.output")
        let outputHandler = { (data: Data?) in
            dispatchPrecondition(condition: .onQueue(outputQueue))

            outputSync.enter()
            defer { outputSync.leave() }

            guard let _output = data.flatMap({ String(data: $0, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(["\n"])) }), !_output.isEmpty else {
                return
            }

            output += _output + "\n"

            print(String(repeating: " ", count: 2), terminator: "")
            print(_output)
            fflush(stdout)
        }

        let pipe = Pipe()
        pipe.fileHandleForReading.readabilityHandler = { fileHandle in outputQueue.async { outputHandler(fileHandle.availableData) } }

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
            outputQueue.async {
                outputHandler(try? pipe.fileHandleForReading.readToEnd())
            }
        }

        try process.run()
        process.waitUntilExit()

        // wait for output to be full processed
        outputSync.wait()

        if process.terminationStatus != 0 {
            throw ShellError.processFailed([executable.string] + arguments, process.terminationStatus)
        }

        return output
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
