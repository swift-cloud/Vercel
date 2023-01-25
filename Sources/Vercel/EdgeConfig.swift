//
//  EdgeConfig.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import Foundation

private let edgeConfigIdPrefix = "ecfg_"

public struct EdgeConfig: Sendable {

    public static let `default` = try! EdgeConfig(Vercel.Environment.edgeConfig)

    public let id: String

    private let config: [String: Sendable]

    public init(_ input: String) throws {
        // Parse id from url or input
        let id = try EdgeConfig.parseConfigID(input)
        // Read data from local file system
        guard let data = FileManager.default.contents(atPath: "/opt/edge-config/\(id).json") else {
            throw EdgeConfigError.embeddedConfigNotFound
        }
        self.id = id
        self.config = try JSONSerialization.jsonObject(with: data) as! [String: Sendable]
    }
}

extension EdgeConfig {

    public var digest: String {
        config["digest"] as! String
    }

    public var items: [String: Sendable] {
        config["items"] as! [String: Sendable]
    }

    public func get(_ key: String) -> Claim {
        return .init(items[key])
    }

    public func has(_ key: String) -> Bool {
        return items[key] != nil
    }

    public subscript(key: String) -> Claim {
        return self.get(key)
    }
}

extension EdgeConfig {

    internal static func parseConfigID(_ input: String) throws -> String {
        if input.hasPrefix(edgeConfigIdPrefix) {
            return input
        }
        if input.hasPrefix("https://") {
            guard let url = URL(string: input) else {
                throw EdgeConfigError.invalidConnection
            }
            guard let id = url.pathComponents.first(where: { $0.hasPrefix(edgeConfigIdPrefix) }) else {
                throw EdgeConfigError.invalidConnection
            }
            return id
        }
        if let value = Vercel.Environment[input] {
            return try parseConfigID(value)
        }
        throw EdgeConfigError.invalidConnection
    }
}

public enum EdgeConfigError: Error {
    case invalidConnection
    case embeddedConfigNotFound
}
