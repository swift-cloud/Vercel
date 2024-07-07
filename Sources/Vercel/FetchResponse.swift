//
//  FetchResponse.swift
//
//
//  Created by Andrew Barba on 7/7/24.
//

import HTTPTypes

public struct FetchResponse: Sendable {
    
    public let response: HTTPResponse

    internal let body: Data?
}

extension FetchResponse {

    public var status: HTTPResponse.Status {
        response.status
    }

    public var ok: Bool {
        return status.code >= 200 && status.code <= 299
    }
}

extension FetchResponse {

    public func decode<T>(decoder: JSONDecoder = .init()) async throws -> T where T: Decodable & Sendable {
        let data = try await data()
        return try decoder.decode(T.self, from: data)
    }

    public func decode<T>(_ type: T.Type, decoder: JSONDecoder = .init()) async throws -> T where T: Decodable & Sendable {
        let data = try await data()
        return try decoder.decode(type, from: data)
    }

    public func json() async throws -> Any {
        let data = try await data()
        return try JSONSerialization.jsonObject(with: data)
    }

    public func jsonObject() async throws -> [String: Any] {
        let data = try await data()
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    public func jsonArray() async throws -> [Any] {
        let data = try await data()
        return try JSONSerialization.jsonObject(with: data) as! [Any]
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
        let data = try await data()
        return String(data: data, encoding: .utf8) ?? ""
    }

    public func bytes() async throws -> [UInt8] {
        let data = try await data()
        return .init(data)
    }

    public func data() async throws -> Data {
        return self.body ?? .init()
    }
}
