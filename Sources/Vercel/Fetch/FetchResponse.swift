//
//  File.swift
//  
//
//  Created by Andrew Barba on 1/22/23.
//

public struct FetchResponse: Sendable {

    public let body: Data

    public let headers: [String: String]

    public let status: Int

    public let url: URL
}

extension FetchResponse {

    public var ok: Bool {
        return status >= 200 && status <= 299
    }
}

extension FetchResponse {

    public func decode<T>(decoder: JSONDecoder = .init()) async throws -> T where T: Decodable & Sendable {
        return try decoder.decode(T.self, from: body)
    }

    public func decode<T>(_ type: T.Type, decoder: JSONDecoder = .init()) async throws -> T where T: Decodable & Sendable {
        return try decoder.decode(type, from: body)
    }

    public func json() async throws -> Any {
        return try JSONSerialization.jsonObject(with: body)
    }

    public func jsonObject() async throws -> [String: Any] {
        return try JSONSerialization.jsonObject(with: body) as! [String: Any]
    }

    public func jsonArray() async throws -> [Any] {
        return try JSONSerialization.jsonObject(with: body) as! [Any]
    }

    public func text() async throws -> String {
        return String(data: body, encoding: .utf8)!
    }

    public func data() async throws -> Data {
        return body
    }

    public func bytes() async throws -> [UInt8] {
        return body.bytes
    }
}
