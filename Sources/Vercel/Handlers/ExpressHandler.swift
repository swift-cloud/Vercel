//
//  ExpressHandler.swift
//
//
//  Created by Andrew Barba on 1/21/23.
//

public protocol ExpressHandler: RequestHandler {

    static var router: Router { get }
}

extension ExpressHandler {

    public func onRequest(_ req: Request) async throws -> Response {
        return try await Self.router.run(req)
    }
}
