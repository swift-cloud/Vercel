//
//  EdgeConfig.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import Foundation

public struct EdgeConfig: Sendable {

    public static let `default` = try! EdgeConfig(Environment.edgeConfig)

    public let id: String

    private let config: EmbeddedEdgeConfig

    public init(_ connection: String) throws {
        guard let url = URLComponents(string: connection) else {
            throw EdgeConfigError.invalidConnection
        }
        guard url.host == "edge-config.vercel.com" else {
            throw EdgeConfigError.invalidConnection
        }
        guard url.path.starts(with: "/ecfg") else {
            throw EdgeConfigError.invalidConnection
        }
        guard let id = url.path.components(separatedBy: "/").last else {
            throw EdgeConfigError.invalidConnection
        }
        guard let data = FileManager.default.contents(atPath: "/opt/edge-config/\(id).json") else {
            throw EdgeConfigError.embeddedConfigNotFound
        }
        self.id = id
        self.config = try JSONDecoder().decode(EmbeddedEdgeConfig.self, from: data)
    }
}

extension EdgeConfig {

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
