//
//  ExpressHandler.swift
//
//
//  Created by Andrew Barba on 1/21/23.
//

import AWSLambdaRuntime

public protocol ExpressHandler: RequestHandler {

    static var basePath: String { get }

    static func configure(router: Router) async throws
}

extension ExpressHandler {

    public static var basePath: String {
        return "/"
    }

    public static func setup(context: LambdaInitializationContext) async throws {
        // Create the router
        let router = Router(prefix: basePath)
        // Configure router in user code
        try await configure(router: router)
        // Cache the app instance
        Shared.router = router
    }

    public func onRequest(_ req: Request) async throws -> Response {
        guard let router = Shared.router else {
            return .status(.serviceUnavailable).send("Express router not configured")
        }
        return try await router.run(req)
    }
}

fileprivate struct Shared {

    static var router: Router?
}
