//
//  Environment.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import AWSLambdaRuntime

extension Vercel {
    public struct Environment: Sendable {

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
}

extension Vercel.Environment {

    public static var edgeConfig = Self["EDGE_CONFIG"]!

    public static var vercelEnvironment = Self["VERCEL_ENV", default: "dev"]

    public static var vercelHostname = Self["VERCEL_URL", default: "localhost"]

    public static var vercelRegion = Self["VERCEL_REGION", default: "dev1"]
}
