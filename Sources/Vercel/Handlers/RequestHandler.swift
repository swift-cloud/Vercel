//
//  RequestHandler.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import AWSLambdaRuntime

public protocol RequestHandler: SimpleLambdaHandler {

    func onRequest(_ req: Request, context: Context) async throws -> Response
}

extension RequestHandler {

    public func handle(_ event: InvokeEvent, context: LambdaContext) async throws -> Response {
        let data = Data(event.body.utf8)
        let payload = try JSONDecoder().decode(InvokeEvent.Payload.self, from: data)
        return try await onRequest(.init(payload), context: .init(context))
    }
}
