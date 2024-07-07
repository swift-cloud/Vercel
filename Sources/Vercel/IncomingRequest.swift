//
//  IncomingRequest.swift
//
//
//  Created by Andrew Barba on 7/7/24.
//

import AWSLambdaRuntime
import HTTPTypes

public struct IncomingRequest: Sendable {

    public let request: HTTPRequest

    public let body: String?

    public let context: LambdaContext

    public internal(set) var pathParameters: Parameters = .init()
}

extension IncomingRequest {

    public var url: URL {
        request.url!
    }

    public var path: String {
        request.url!.path
    }

    public var rawPath: String {
        request.path!
    }

    public var method: HTTPRequest.Method {
        request.method
    }

    public var headerFields: HTTPFields {
        request.headerFields
    }
}

extension IncomingRequest {

    public var vercelID: String {
        let field = HTTPField.Name("x-vercel-id")!
        return request.headerFields[field] ?? "dev1:dev1::00000-0000000000000-000000000000"
    }

    public var vercelClientIPAddress: String {
        let field = HTTPField.Name("x-vercel-forwarded-for")!
        return request.headerFields[field] ?? "127.0.0.1"
    }
}

extension IncomingRequest {

    @TaskLocal
    public static var current: Self?
}
