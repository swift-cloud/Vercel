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

    guard let context = RequestHandlerState.context else {
        throw FetchError.invalidLambdaContext
    }

    let httpClient = HTTPClient(eventLoopGroupProvider: .shared(context.eventLoop))

    let response = try await httpClient.execute(httpRequest, timeout: request.timeout ?? .seconds(60))

    var buffer = try await response.body.collect(upTo: request.maxBodySize ?? .max)

    let data = buffer.readData(length: buffer.readableBytes) ?? .init()

    return FetchResponse(
        body: data,
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
