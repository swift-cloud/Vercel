//
//  RequestHandler.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import AWSLambdaRuntime
import NIOCore

public protocol RequestHandler: EventLoopLambdaHandler where Event == InvokeEvent, Output == Response {

    func onRequest(_ req: Request) async throws -> Response

    static func setup(context: LambdaInitializationContext) async throws

    init()
}

extension RequestHandler {

    public func handle(_ event: InvokeEvent, context: LambdaContext) -> EventLoopFuture<Response> {
        return context.eventLoop.makeFutureWithTask {
            return try await RequestHandlerState.$context.withValue(context) {
                let data = Data(event.body.utf8)
                let payload = try JSONDecoder().decode(InvokeEvent.Payload.self, from: data)
                let req = Request(payload, in: context)
                return try await onRequest(req)
            }
        }
    }

    public static func setup(context: LambdaInitializationContext) async throws {}

    public static func makeHandler(context: LambdaInitializationContext) -> EventLoopFuture<Self> {
        return context.eventLoop.makeFutureWithTask {
            try await setup(context: context)
            return Self()
        }
    }
}

public enum RequestHandlerState {
    
    @TaskLocal
    public static var context: LambdaContext?
}
