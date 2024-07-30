//
//  IncomingRequest.swift
//
//
//  Created by Andrew Barba on 7/7/24.
//

import AWSLambdaRuntime
import HTTPTypes

public struct IncomingRequest: Sendable {
    public struct Body: Sendable {
        public enum Error: Swift.Error {
            case invalidEncoding
        }

        internal let data: Data

        public func bytes() async throws -> [UInt8] {
            return .init(data)
        }

        public func data() async throws -> Data {
            return data
        }

        public func text(encoding: String.Encoding = .utf8) async throws -> String {
            guard let value = String(data: data, encoding: encoding) else {
                throw Error.invalidEncoding
            }
            return value
        }
    }

    public let request: HTTPRequest

    public let body: Body?

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

    public var method: HTTPRequest.Method {
        request.method
    }

    public var headerFields: HTTPFields {
        request.headerFields
    }

    public var searchParams: [String: String] {
        let components = URLComponents(string: request.path ?? "/")
        let searchParams = components?.queryItems?.reduce(into: [:]) {
            $0[$1.name] = $1.value
        }
        return searchParams ?? [:]
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

extension IncomingRequest {

    internal init(_ payload: InvokeEvent.Payload, in context: LambdaContext) {
        let headerFields: HTTPFields = payload.headers.reduce(into: .init()) {
            $0.append(.init(name: .init($1.key)!, value: $1.value))
        }
        let bodyData: Data?
        if let encoding = payload.encoding, let body = payload.body, encoding == "base64" {
            bodyData = Data(base64Encoded: body)
        } else {
            bodyData = payload.body?.data(using: .utf8)
        }
        self.init(
            request: .init(
                method: payload.method,
                scheme: "https",
                authority: payload.headers["host"],
                path: payload.path,
                headerFields: headerFields
            ),
            body: bodyData.map { .init(data: $0) },
            context: context
        )
    }
}
