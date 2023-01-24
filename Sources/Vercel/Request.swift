//
//  Request.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

public struct Request: Sendable {
    public let method: HTTPMethod
    public let headers: HTTPHeaders
    public let path: String
    public let searchParams: [String: String]
    public let body: String?

    /// Private instance var to prevent decodable from failing
    public internal(set) var pathParams: Parameters = .init()

    internal init(_ payload: InvokeEvent.Payload) {
        self.method = payload.method
        self.headers = payload.headers
        self.path = payload.path
        self.body = payload.body
        self.searchParams = URLComponents(string: payload.path)?
            .queryItems?
            .reduce(into: [:]) { $0[$1.name] = $1.value } ?? [:]
    }
}

extension Request {

    public var id: String {
        header(.xVercelId) ?? "dev1:dev1::00000-0000000000000-000000000000"
    }

    public var host: String {
        header(.host) ?? "localhost"
    }

    public var userAgent: String {
        header(.userAgent) ?? "unknown"
    }

    public var clientIPAddress: String {
        header(.xVercelForwardedFor) ?? "127.0.0.1"
    }

    public var url: URL {
        return .init(string: "https://\(host)\(path)")!
    }

    public func header(_ key: String) -> String? {
        return headers[key]?.value
    }

    public func header(_ key: HTTPHeaderKey) -> String? {
        return headers[key.rawValue]?.value
    }
}
