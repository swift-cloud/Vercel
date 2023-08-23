//
//  RequestHandler.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

public protocol RequestHandler: SimpleLambdaHandler {

    func onRequest(_ req: Request) async throws -> Response
}

extension RequestHandler {

    public func handle(_ event: InvokeEvent, context: LambdaContext) async throws -> Response {
        let data = Data(event.body.utf8)
        let payload = try JSONDecoder().decode(InvokeEvent.Payload.self, from: data)
        let req = Request(payload, in: context)
        return try await onRequest(req)
    }
}
