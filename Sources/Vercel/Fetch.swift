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
    case timeout
    case invalidLambdaContext
}

public struct FetchResponse: Sendable {
    let response: HTTPResponse
    let data: Data?
}

public func fetch(_ httpRequest: HTTPRequest) async throws -> FetchResponse {
    return try await withCheckedThrowingContinuation { continuation in
        guard let urlRequest = URLRequest(httpRequest: httpRequest) else {
            continuation.resume(throwing: FetchError.invalidRequest)
            return
        }
        let task = URLSession.shared.dataTask(with: urlRequest) { data, urlResponse, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            guard let response = (urlResponse as? HTTPURLResponse)?.httpResponse else {
                continuation.resume(throwing: FetchError.invalidResponse)
                return
            }
            continuation.resume(returning: .init(response: response, data: data))
        }
        task.resume()
    }
}

public func fetch(_ url: URL) async throws -> FetchResponse {
    let request = HTTPRequest(url: url)
    return try await fetch(request)
}

public func fetch(_ urlPath: String) async throws -> FetchResponse {
    guard let url = URL(string: urlPath) else {
        throw FetchError.invalidRequest
    }
    return try await fetch(url)
}
