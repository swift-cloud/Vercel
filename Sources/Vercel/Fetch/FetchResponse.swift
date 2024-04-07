//
//  FetchResponse.swift
//  
//
//  Created by Andrew Barba on 1/22/23.
//

import AsyncHTTPClient
import NIOCore
import NIOFoundationCompat

public struct FetchResponse: Sendable {

    public let body: HTTPClientResponse.Body

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
        let bytes = try await self.bytes()
        return try decoder.decode(T.self, from: bytes)
    }

    public func decode<T>(_ type: T.Type, decoder: JSONDecoder = .init()) async throws -> T where T: Decodable & Sendable {
        let bytes = try await self.bytes()
        return try decoder.decode(type, from: bytes)
    }

    public func json() async throws -> Any {
        let bytes = try await self.bytes()
        return try JSONSerialization.jsonObject(with: bytes)
    }

    public func jsonObject() async throws -> [String: Any] {
        let bytes = try await self.bytes()
        return try JSONSerialization.jsonObject(with: bytes) as! [String: Any]
    }

    public func jsonArray() async throws -> [Any] {
        let bytes = try await self.bytes()
        return try JSONSerialization.jsonObject(with: bytes) as! [Any]
    }

    public func formValues() async throws -> [String: String] {
        let query = try await self.text()
        let components = URLComponents(string: "?\(query)")
        let queryItems = components?.queryItems ?? []
        return queryItems.reduce(into: [:]) { values, item in
            values[item.name] = item.value
        }
    }

    public func text() async throws -> String {
        var bytes = try await self.bytes()
        return bytes.readString(length: bytes.readableBytes) ?? ""
    }

    public func data() async throws -> Data {
        var bytes = try await self.bytes()
        return bytes.readData(length: bytes.readableBytes) ?? .init()
    }

    public func bytes(upTo maxBytes: Int = .max) async throws -> ByteBuffer {
        return try await body.collect(upTo: maxBytes)
    }
}
