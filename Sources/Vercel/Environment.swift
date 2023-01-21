//
//  Environment.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import AWSLambdaRuntime

public struct Environment: Sendable {

    public static let current = Environment()

    public func get(_ key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }

    public func get(_ key: String, default value: String) -> String {
        return ProcessInfo.processInfo.environment[key, default: value]
    }

    public subscript(key: String) -> String? {
        return self.get(key)
    }

    public subscript(key: String, default value: String) -> String {
        return self.get(key, default: value)
    }
}

extension Environment {

    public static var edgeConfig = current["EDGE_CONFIG"]!
}
