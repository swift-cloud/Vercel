//
//  EdgeConfig.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import Foundation

private let edgeConfigIdPrefix = "ecfg_"

public struct EdgeConfig: Sendable {

    public static let `default` = try! EdgeConfig(Environment.edgeConfig)

    public let id: String

    private let config: EmbeddedEdgeConfig

    public init(_ input: String) throws {
        // Check for matching environment variable
        let connection = Environment.current[input, default: input]
        // Parse id from url or input
        let id = connection.components(separatedBy: "/").first { $0.hasPrefix(edgeConfigIdPrefix) }
        // Ensure we have a valid id
        guard let id = id else {
            throw EdgeConfigError.invalidConnection
        }
        // Read data from local file system
        guard let data = FileManager.default.contents(atPath: "/opt/edge-config/\(id).json") else {
            throw EdgeConfigError.embeddedConfigNotFound
        }
        self.id = id
        self.config = try JSONDecoder().decode(EmbeddedEdgeConfig.self, from: data)
    }
}

extension EdgeConfig {

    public var digest: String {
        config.digest
    }

    public func get(_ key: String) -> String? {
        return config.items[key]
    }

    public func get(_ key: String, default value: String) -> String {
        return config.items[key, default: value]
    }

    public func has(_ key: String) -> Bool {
        return config.items[key] != nil
    }

    public subscript(key: String) -> String? {
        return self.get(key)
    }

    public subscript(key: String, default value: String) -> String {
        return self.get(key, default: value)
    }
}

fileprivate struct EmbeddedEdgeConfig: Codable, Sendable {
    let digest: String
    let items: [String: String]
}

public enum EdgeConfigError: Error {
    case invalidConnection
    case embeddedConfigNotFound
}
