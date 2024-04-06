//
//  Environment.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import AWSLambdaRuntime

public struct VercelEnvironment: Sendable {

    public static func get(_ key: String) -> String? {
        return Lambda.env(key)
    }

    public static func get(_ key: String, default value: String) -> String {
        return Lambda.env(key) ?? value
    }

    public static subscript(key: String) -> String? {
        return get(key)
    }

    public static subscript(key: String, default value: String) -> String {
        return get(key, default: value)
    }
}

extension VercelEnvironment {

    public static let edgeConfig = Self["EDGE_CONFIG"]!

    public static let vercelEnvironment = Self["VERCEL_ENV", default: "dev"]

    public static let vercelHostname = Self["VERCEL_URL", default: "localhost"]

    public static let vercelRegion = Self["VERCEL_REGION", default: "dev1"]
}
