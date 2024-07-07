//
//  VaporHandler.swift
//
//
//  Created by Andrew Barba on 8/25/23.
//

import AWSLambdaRuntime
import HTTPTypes
import Vapor
import Vercel

public protocol VaporHandler: RequestHandler {

    static var environment: Environment { get }

    static func configure(app: Application) async throws
}

extension VaporHandler {

    public static var environment: Environment {
        .development
    }

    public static func setup(context: LambdaInitializationContext) async throws {
        let app = try await Application.make(environment, .shared(context.eventLoop))
        // Request vapor application from user code
        try await configure(app: app)
        // Configure vercel server
        app.servers.use(.vercel)
        // Cache the app instance
        await Shared.default.setApp(app)
    }

    public func onRequest(_ req: IncomingRequest) async throws -> OutgoingResponse {
        guard let app = await Shared.default.app else {
            return .status(.serviceUnavailable).send("Vapor application not configured")
        }
        let vaporRequest = try Vapor.Request.from(request: req, for: app)
        let vaporResponse = try await app.responder.respond(to: vaporRequest).get()
        return try await .from(response: vaporResponse, on: app.eventLoopGroup.next())
    }
}

private actor Shared {

    static let `default` = Shared()

    private(set) var app: Application?

    func setApp(_ app: Application) {
        self.app = app
    }
}

extension Vapor.Request {

    static func from(request: IncomingRequest, for app: Application) throws -> Self {
        let buffer = request.body.map { data in
            var _buffer = request.context.allocator.buffer(capacity: data.count)
            _buffer.writeBytes(data.utf8)
            return _buffer
        }

        let nioHeaders = request.headerFields.reduce(into: NIOHTTP1.HTTPHeaders()) {
            $0.add(name: $1.name.canonicalName, value: $1.value)
        }

        return try .init(
            application: app,
            method: .init(rawValue: request.method.rawValue),
            url: .init(string: request.rawPath),
            version: HTTPVersion(major: 1, minor: 1),
            headers: nioHeaders,
            collectedBody: buffer,
            remoteAddress: .init(ipAddress: request.vercelClientIPAddress, port: 443),
            logger: app.logger,
            on: app.eventLoopGroup.next()
        )
    }
}

extension OutgoingResponse {

    static func from(response: Vapor.Response, on eventLoop: EventLoop) async throws -> Self {
        // Create status code
        let status = HTTPResponse.Status(
            code: .init(response.status.code),
            reasonPhrase: response.status.reasonPhrase
        )

        // Create the headers
        let headerFields: HTTPFields = response.headers.reduce(into: [:]) {
            let field = HTTPField.Name($1.name)!
            $0[field] = .init($1.value)
        }

        // Stream the body to a future
        let future = response.body.collect(on: eventLoop).map {
            var buffer = $0
            let byteLength = buffer?.readableBytes ?? 0
            let bytes = buffer?.readBytes(length: byteLength)
            return OutgoingResponse(
                status: status,
                headerFields: headerFields,
                body: bytes?.base64String(),
                encoding: bytes.map { _ in .base64 }
            )
        }

        return try await future.get()
    }
}
