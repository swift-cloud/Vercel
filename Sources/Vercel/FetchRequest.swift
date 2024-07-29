//
//  FetchRequest.swift
//
//
//  Created by Andrew Barba on 1/22/23.
//

import Foundation
import HTTPTypes

public struct FetchRequest: Sendable {

    public var url: URL

    public var method: HTTPRequest.Method

    public var headers: [String: String]

    public var searchParams: [String: String]

    public var body: Body?

    public var timeoutInterval: TimeInterval? = nil

    public init(
        url: URL,
        method: HTTPRequest.Method = .get,
        body: Body? = nil,
        headers: [String: String] = [:],
        searchParams: [String: String] = [:],
        timeoutInterval: TimeInterval? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.searchParams = searchParams
        self.body = body
        self.timeoutInterval = timeoutInterval
    }
}

extension FetchRequest {

    public enum Body: Sendable {
        case bytes(_ bytes: [UInt8])
        case data(_ data: Data)
        case text(_ text: String)
        case json(_ json: Data)

        public static func json<T>(_ value: T, encoder: JSONEncoder = .init()) throws -> Body where T: Encodable {
            let data = try encoder.encode(value)
            return Body.json(data)
        }

        public static func json(_ jsonObject: [String: Any]) throws -> Body {
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            return Body.json(data)
        }

        public static func json(_ jsonArray: [Any]) throws -> Body {
            let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
            return Body.json(data)
        }

        public var defaultContentType: String? {
            switch self {
            case .json:
                return "application/json"
            default:
                return nil
            }
        }
    }
}
