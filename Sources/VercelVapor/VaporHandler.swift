//
//  VaporHandler.swift
//
//
//  Created by Andrew Barba on 8/25/23.
//

import AWSLambdaRuntime
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
        let app = Application(environment, .shared(context.eventLoop))
        // Request vapor application from user code
        try await configure(app: app)
        // Configure vercel server
        app.servers.use(.vercel)
        // Start the application
        try await app.startup()
        // Cache the app instance
        await MainActor.run {
            Shared.app = app
        }
    }

    public func onRequest(_ req: Vercel.Request) async throws -> Vercel.Response {
        guard let app = await Shared.app else {
            return .status(.serviceUnavailable).send("Vapor application not configured")
        }
        let vaporRequest = try Vapor.Request.from(request: req, for: app)
        let vaporResponse = try await app.responder.respond(to: vaporRequest).get()
        return try await .from(response: vaporResponse, on: app.eventLoopGroup.next())
    }
}

private struct Shared {

    @MainActor
    static var app: Application?
}

extension Vapor.Request {

    static func from(request: Vercel.Request, for app: Application) throws -> Self {
        let buffer = request.rawBody.map { data in
            var _buffer = request.context.allocator.buffer(capacity: data.count)
            _buffer.writeBytes(data)
            return _buffer
        }

        let nioHeaders = request.headers.reduce(into: NIOHTTP1.HTTPHeaders()) {
            $0.add(name: $1.key, value: $1.value.value)
        }

        var url: String = request.path

        if request.searchParams.count > 0, let search = request.search {
            url += "?\(search)"
        }

        return try .init(
            application: app,
            method: .init(rawValue: request.method.rawValue),
            url: .init(path: url),
            version: HTTPVersion(major: 1, minor: 1),
            headers: nioHeaders,
            collectedBody: buffer,
            remoteAddress: .init(ipAddress: request.clientIPAddress, port: 443),
            logger: app.logger,
            on: app.eventLoopGroup.next()
        )
    }
}

extension Vercel.Response {

    static func from(response: Vapor.Response, on eventLoop: EventLoop) async throws -> Self {
        // Create status code
        let statusCode = Vercel.HTTPResponseStatus(
            code: response.status.code,
            reasonPhrase: response.status.reasonPhrase
        )

        // Create the headers
        let headers: [String: HTTPHeaderValue] = response.headers.reduce(into: [:]) {
            $0[$1.name] = .init($1.value)
        }

        // Stream the body to a future
        let future = response.body.collect(on: eventLoop).map {
            var buffer = $0
            let byteLength = buffer?.readableBytes ?? 0
            let bytes = buffer?.readBytes(length: byteLength)
            return Vercel.Response(
                statusCode: statusCode,
                headers: headers,
                body: bytes?.base64String(),
                encoding: bytes.map { _ in .base64 }
            )
        }

        return try await future.get()
    }
}
