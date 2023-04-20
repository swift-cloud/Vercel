//
//  Fetch.swift
//  
//
//  Created by Andrew Barba on 1/22/23.
//

import Foundation
import AsyncHTTPClient
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)

public enum FetchError: Error, Sendable {
    case invalidResponse
    case invalidURL
    case timeout
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
    var _req = HTTPClientRequest(url: url.absoluteString)

    // Set request method
    httpRequest.httpMethod = request.method.rawValue
    _req.method = .init(rawValue: request.method.rawValue)

    // Set the timeout interval
    if let timeoutInterval = request.timeoutInterval {
        httpRequest.timeoutInterval = timeoutInterval
    }

    // Set default content type based on body
    if let contentType = request.body?.defaultContentType {
        let name = HTTPHeaderKey.contentType.rawValue
        httpRequest.setValue(request.headers[name] ?? contentType, forHTTPHeaderField: name)
        _req.headers.add(name: name, value: request.headers[name] ?? contentType)
    }

    // Set headers
    for (key, value) in request.headers {
        httpRequest.setValue(value, forHTTPHeaderField: key)
        _req.headers.add(name: key, value: value)
    }

    // Write bytes to body
    switch request.body {
    case .bytes(let bytes):
        httpRequest.httpBody = Data(bytes)
        _req.body = .bytes(bytes)
    case .data(let data):
        httpRequest.httpBody = data
        _req.body = .bytes(data)
    case .text(let text):
        httpRequest.httpBody = Data(text.utf8)
        _req.body = .bytes(Data(text.utf8))
    case .json(let json):
        httpRequest.httpBody = json
        _req.body = .bytes(json)
    case .none:
        break
    }

    let _res = try await httpClient.execute(_req, timeout: .seconds(30))

    _res.body.

    let (data, response): (Data, HTTPURLResponse) = try await withCheckedThrowingContinuation { continuation in
        let task = URLSession.shared.dataTask(with: httpRequest) { data, response, error in
            if let data, let response = response as? HTTPURLResponse {
                continuation.resume(returning: (data, response))
            } else {
                continuation.resume(throwing: error ?? FetchError.invalidResponse)
            }
        }
        task.resume()
    }

    return FetchResponse(
        body: data,
        headers: response.allHeaderFields as! [String: String],
        status: response.statusCode,
        url: url
    )
}

public func fetch(_ url: URL, _ options: FetchRequest.Options = .options()) async throws -> FetchResponse {
    let request = FetchRequest(url, options)
    return try await fetch(request)
}

public func fetch(_ urlPath: String, _ options: FetchRequest.Options = .options()) async throws -> FetchResponse {
    guard let url = URL(string: urlPath) else {
        throw FetchError.invalidURL
    }
    let request = FetchRequest(url, options)
    return try await fetch(request)
}
