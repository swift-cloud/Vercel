//
//  Fetch.swift
//  
//
//  Created by Andrew Barba on 1/22/23.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum FetchError: Error, Sendable {
    case invalidRequest
    case invalidResponse
    case invalidURL
    case timeout
    case invalidLambdaContext
}

public func fetch(_ request: FetchRequest) async throws -> FetchResponse {
    // Build url components from request url
    guard var urlComponents = URLComponents(string: request.url.absoluteString) else {
        throw FetchError.invalidURL
    }

    // Set default scheme
    urlComponents.scheme = urlComponents.scheme ?? "http"

    // Set default host
    urlComponents.host = urlComponents.host ?? "localhost"

    // Set default query params
    urlComponents.queryItems = urlComponents.queryItems ?? []

    // Build search params
    for (key, value) in request.searchParams {
        urlComponents.queryItems?.append(.init(name: key, value: value))
    }

    // Parse final url
    guard let url = urlComponents.url else {
        throw FetchError.invalidURL
    }

    // Set request resources
    var httpRequest = URLRequest(url: url)

    // Set request method
    httpRequest.httpMethod = request.method.rawValue

    // Set the timeout interval
    if let timeoutInterval = request.timeoutInterval {
        httpRequest.timeoutInterval = timeoutInterval
    }

    // Set default content type based on body
    if let contentType = request.body?.defaultContentType {
        let name = HTTPField.Name.contentType.canonicalName
        httpRequest.setValue(request.headers[name] ?? contentType, forHTTPHeaderField: name)
    }

    // Set headers
    for (key, value) in request.headers {
        httpRequest.setValue(value, forHTTPHeaderField: key)
    }

    // Write bytes to body
    switch request.body {
    case .bytes(let bytes):
        httpRequest.httpBody = Data(bytes)
    case .data(let data):
        httpRequest.httpBody = data
    case .text(let text):
        httpRequest.httpBody = Data(text.utf8)
    case .json(let json):
        httpRequest.httpBody = json
    case .none:
        break
    }

    return try await withCheckedThrowingContinuation { continuation in
        let task = URLSession.shared.dataTask(with: httpRequest) { data, urlResponse, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            guard let response = (urlResponse as? HTTPURLResponse)?.httpResponse else {
                continuation.resume(throwing: FetchError.invalidResponse)
                return
            }
            continuation.resume(returning: .init(response: response, body: data))
        }
        task.resume()
    }
}

public func fetch(
    _ url: URL,
    method: HTTPRequest.Method = .get,
    body: FetchRequest.Body? = nil,
    headers: [String: String] = [:],
    searchParams: [String: String] = [:],
    timeoutInterval: TimeInterval? = nil
) async throws -> FetchResponse {
    let request = FetchRequest(
        url: url,
        method: method,
        body: body,
        headers: headers,
        searchParams: searchParams,
        timeoutInterval: timeoutInterval
    )
    return try await fetch(request)
}

public func fetch(
    _ urlPath: String,
    method: HTTPRequest.Method = .get,
    body: FetchRequest.Body? = nil,
    headers: [String: String] = [:],
    searchParams: [String: String] = [:],
    timeoutInterval: TimeInterval? = nil
) async throws -> FetchResponse {
    guard let url = URL(string: urlPath) else {
        throw FetchError.invalidRequest
    }
    return try await fetch(
        url,
        method: method,
        body: body,
        headers: headers,
        searchParams: searchParams,
        timeoutInterval: timeoutInterval
    )
}
