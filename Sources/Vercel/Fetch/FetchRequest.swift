//
//  FetchRequest.swift
//  
//
//  Created by Andrew Barba on 1/22/23.
//

import NIOCore

public struct FetchRequest: Sendable {

    public var url: URL

    public var method: HTTPMethod

    public var headers: [String: String]

    public var searchParams: [String: String]

    public var body: Body?

    public var timeout: TimeAmount? = nil

    public var maxBodySize: Int? = nil

    public init(_ url: URL, _ options: Options = .options()) {
        self.url = url
        self.method = options.method
        self.headers = options.headers
        self.searchParams = options.searchParams
        self.body = options.body
        self.timeout = options.timeout
        self.maxBodySize = options.maxBodySize
    }
}

extension FetchRequest {

    public struct Options {

        public var method: HTTPMethod = .GET

        public var body: Body? = nil

        public var headers: [String: String] = [:]

        public var searchParams: [String: String] = [:]

        public var timeout: TimeAmount? = nil

        public var maxBodySize: Int? = nil

        public static func options(
            method: HTTPMethod = .GET,
            body: Body? = nil,
            headers: [String: String] = [:],
            searchParams: [String: String] = [:],
            timeout: TimeAmount? = nil,
            maxBodySize: Int? = nil
        ) -> Options {
            return Options(
                method: method,
                body: body,
                headers: headers,
                searchParams: searchParams,
                timeout: timeout,
                maxBodySize: maxBodySize
            )
        }
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
