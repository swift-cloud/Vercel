//
//  VercelServer.swift
//  
//
//  Created by Andrew Barba on 8/22/23.
//

import AWSLambdaRuntime
import NIO
import NIOHTTP1
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
        try app.start()
        // Cache the app instance
        VercelShared.app = app
    }

    public func onRequest(_ req: Vercel.Request) async throws -> Vercel.Response {
        guard let app = VercelShared.app else {
            return .status(.serviceUnavailable).send("Vapor application not configured")
        }
        let vaporRequest = try Vapor.Request(req: req, for: app)
        let vaporResponse = try await app.responder.respond(to: vaporRequest).get()
        return try await Vercel.Response.from(response: vaporResponse, on: req.context!.eventLoop).get()
    }
}

fileprivate struct VercelShared {

    static var app: Application?
}

public final class VercelServer: Server {

    private let application: Application

    private let eventLoop: EventLoop

    public init(application: Application) {
        self.application = application
        self.eventLoop = application.eventLoopGroup.next()
    }

    public var onShutdown: EventLoopFuture<Void> {
        return eventLoop.makeSucceededVoidFuture()
    }

    public func start(hostname _: String?, port _: Int?) throws {
        // do nothing and let the lambda runtime manage the http server
    }

    public func shutdown() {
        // do nothing and let the lambda runtime manage lifecycle
    }
}

extension Application.Servers.Provider {
    public static var vercel: Self {
        .init {
            $0.servers.use { app in
                VercelServer(application: app)
            }
        }
    }
}

extension Vapor.Request {
    private static let bufferAllocator = ByteBufferAllocator()

    convenience init(req: Vercel.Request, for application: Application) throws {
        var buffer: NIO.ByteBuffer?
        if let data = req.rawBody {
            buffer = Self.bufferAllocator.buffer(capacity: data.count)
            buffer!.writeBytes(data)
        }

        var nioHeaders = NIOHTTP1.HTTPHeaders()
        req.headers.forEach { key, value in
            nioHeaders.add(name: key, value: value.value)
        }

        var url: String = req.path

        if req.searchParams.count > 0, let search = req.search {
            url += "?\(search)"
        }

        self.init(
            application: application,
            method: NIOHTTP1.HTTPMethod(rawValue: req.method.rawValue),
            url: Vapor.URI(path: url),
            version: HTTPVersion(major: 1, minor: 1),
            headers: nioHeaders,
            collectedBody: buffer,
            remoteAddress: nil,
            logger: req.context!.logger,
            on: req.context!.eventLoop
        )
    }
}

extension Vercel.Response {
    static func from(response: Vapor.Response, on eventLoop: EventLoop) -> EventLoopFuture<Vercel.Response> {
        // Create status code
        let statusCode = Vercel.HTTPResponseStatus(
            code: response.status.code,
            reasonPhrase: response.status.reasonPhrase
        )

        // Create the headers
        let headers: [String: HTTPHeaderValue] = response.headers.reduce(into: [:]) {
            $0[$1.name] = .init($1.value)
        }

        // Can we access the body right away?
        if let string = response.body.string {
            return eventLoop.makeSucceededFuture(.init(
                statusCode: statusCode,
                headers: headers,
                body: string,
                isBase64Encoded: false
            ))
        } else if let bytes = response.body.data {
            return eventLoop.makeSucceededFuture(.init(
                statusCode: statusCode,
                headers: headers,
                body: bytes.base64EncodedString(),
                isBase64Encoded: true
            ))
        } else {
            // See if it is a stream and try to gather the data
            return response.body.collect(on: eventLoop).map { buffer -> Vercel.Response in
                // Was there any content
                guard
                    var buffer = buffer,
                    let bytes = buffer.readBytes(length: buffer.readableBytes)
                else {
                    return Vercel.Response(statusCode: statusCode, headers: headers)
                }

                // Done
                return Vercel.Response(
                    statusCode: statusCode,
                    headers: headers,
                    body: bytes.base64String(),
                    isBase64Encoded: true
                )
            }
        }
    }
}
