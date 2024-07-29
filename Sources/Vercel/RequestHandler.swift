//
//  RequestHandler.swift
//
//
//  Created by Andrew Barba on 1/21/23.
//

import AWSLambdaRuntime
import HTTPTypes
import NIOCore

public protocol RequestHandler: Sendable & EventLoopLambdaHandler
where Event == InvokeEvent, Output == InvokeResponse {

    func onRequest(_ req: IncomingRequest) async throws -> OutgoingResponse

    static func setup(context: LambdaInitializationContext) async throws

    init()
}

extension RequestHandler {

    public func handle(
        _ event: InvokeEvent,
        context: LambdaContext
    ) -> EventLoopFuture<InvokeResponse> {
        return context.eventLoop.makeFutureWithTask {
            let data = Data(event.body.utf8)
            let payload = try JSONDecoder().decode(InvokeEvent.Payload.self, from: data)
            let request = IncomingRequest(payload, in: context)
            return try await IncomingRequest.$current.withValue(request) {
                let response = try await onRequest(request)
                let headers: [String: String] = response.response.headerFields.reduce(into: [:]) {
                    $0[$1.name.canonicalName] = $1.value
                }
                return .init(
                    statusCode: response.response.status.code,
                    headers: headers,
                    body: response.body,
                    encoding: response.encoding
                )
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
