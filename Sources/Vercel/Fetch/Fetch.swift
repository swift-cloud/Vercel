//
//  Fetch.swift
//  
//
//  Created by Andrew Barba on 1/22/23.
//

import Foundation
import AsyncHTTPClient

public enum FetchError: Error, Sendable {
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
    var httpRequest = HTTPClientRequest(url: url.absoluteString)

    // Set request method
    httpRequest.method = .init(rawValue: request.method.rawValue)

    // Set default content type based on body
    if let contentType = request.body?.defaultContentType {
        let name = HTTPHeaderKey.contentType.rawValue
        httpRequest.headers.add(name: name, value: request.headers[name] ?? contentType)
    }

    // Set headers
    for (key, value) in request.headers {
        httpRequest.headers.add(name: key, value: value)
    }

    // Write bytes to body
    switch request.body {
    case .bytes(let bytes):
        httpRequest.body = .bytes(bytes)
    case .data(let data):
        httpRequest.body = .bytes(data)
    case .text(let text):
        httpRequest.body = .bytes(Data(text.utf8))
    case .json(let json):
        httpRequest.body = .bytes(json)
    case .none:
        break
    }

    let httpClient = request.httpClient ?? HTTPClient.vercelClient

    let response = try await httpClient.execute(httpRequest, timeout: request.timeout ?? .seconds(60))

    return FetchResponse(
        body: response.body,
        headers: response.headers.reduce(into: [:]) { $0[$1.name] = $1.value },
        status: .init(response.status.code),
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

extension HTTPClient {

    fileprivate static let vercelClient = HTTPClient(
        eventLoopGroup: HTTPClient.defaultEventLoopGroup,
        configuration: .vercelConfiguration
    )
}

extension HTTPClient.Configuration {
    /// The ``HTTPClient/Configuration`` for ``HTTPClient/shared`` which tries to mimic the platform's default or prevalent browser as closely as possible.
    ///
    /// Don't rely on specific values of this configuration as they're subject to change. You can rely on them being somewhat sensible though.
    ///
    /// - note: At present, this configuration is nowhere close to a real browser configuration but in case of disagreements we will choose values that match
    ///   the default browser as closely as possible.
    ///
    /// Platform's default/prevalent browsers that we're trying to match (these might change over time):
    ///  - macOS: Safari
    ///  - iOS: Safari
    ///  - Android: Google Chrome
    ///  - Linux (non-Android): Google Chrome
    fileprivate static var vercelConfiguration: HTTPClient.Configuration {
        // To start with, let's go with these values. Obtained from Firefox's config.
        return HTTPClient.Configuration(
            certificateVerification: .fullVerification,
            redirectConfiguration: .follow(max: 20, allowCycles: false),
            timeout: Timeout(connect: .seconds(90), read: .seconds(90)),
            connectionPool: .seconds(600),
            proxy: nil,
            ignoreUncleanSSLShutdown: false,
            decompression: .enabled(limit: .ratio(10)),
            backgroundActivityLogger: nil
        )
    }
}
