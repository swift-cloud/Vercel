//
//  ExpressHandler.swift
//
//
//  Created by Andrew Barba on 1/21/23.
//

public protocol ExpressHandler: RequestHandler {

    static func configure() async throws -> Router
}

extension ExpressHandler {

    public static func setup() async throws {
        // Request vapor application from user code
        let router = try await configure()
        // Cache the app instance
        ExpressShared.router = router
    }

    public func onRequest(_ req: Request) async throws -> Response {
        guard let router = ExpressShared.router else {
            return .status(.serviceUnavailable).send("Express router not configured")
        }
        return try await router.run(req)
    }
}

fileprivate struct ExpressShared {

    static var router: Router?
}
