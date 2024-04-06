//
//  FetchResponse.swift
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

    public func decode<T>(decoder: JSONDecoder = .init()) throws -> T where T: Decodable & Sendable {
        return try decoder.decode(T.self, from: body)
    }

    public func decode<T>(_ type: T.Type, decoder: JSONDecoder = .init()) throws -> T where T: Decodable & Sendable {
        return try decoder.decode(type, from: body)
    }

    public func json() throws -> Any {
        return try JSONSerialization.jsonObject(with: body)
    }

    public func jsonObject() throws -> [String: Any] {
        return try JSONSerialization.jsonObject(with: body) as! [String: Any]
    }

    public func jsonArray() throws -> [Any] {
        return try JSONSerialization.jsonObject(with: body) as! [Any]
    }

    public func formValues() throws -> [String: String] {
        let query = String(data: body, encoding: .utf8)!
        let components = URLComponents(string: "?\(query)")
        let queryItems = components?.queryItems ?? []
        return queryItems.reduce(into: [:]) { values, item in
            values[item.name] = item.value
        }
    }

    public func text() throws -> String {
        return String(data: body, encoding: .utf8)!
    }

    public func data() throws -> Data {
        return body
    }

    public func bytes() throws -> [UInt8] {
        return Array(body)
    }
}
