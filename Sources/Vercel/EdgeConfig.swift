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
        // Parse id from url or input
        let id = try EdgeConfig.parseConfigID(input)
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

extension EdgeConfig {

    internal static func parseConfigID(_ input: String) throws -> String {
        if input.hasPrefix(edgeConfigIdPrefix) {
            return input
        }
        if input.hasPrefix("https://") {
            let url = URL(string: input)!
            let id = url.path.components(separatedBy: "/").first { $0.hasPrefix(edgeConfigIdPrefix) }
            guard let id else {
                throw EdgeConfigError.embeddedConfigNotFound
            }
            return id
        }
        if let value = Environment.current[input] {
            return try parseConfigID(value)
        }
        throw EdgeConfigError.invalidConnection
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
