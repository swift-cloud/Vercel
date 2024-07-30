//
//  ExpressHandler.swift
//
//
//  Created by Andrew Barba on 1/21/23.
//

import AWSLambdaRuntime

public protocol ExpressHandler: RequestHandler {

    static var basePath: String { get }
    
    static func configure(router: isolated Router) async throws
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
        await Shared.default.setRouter(router)
    }

    public func onRequest(_ req: IncomingRequest) async throws -> OutgoingResponse {
        guard let router = await Shared.default.router else {
            return .status(.serviceUnavailable).send("Express router not configured")
        }
        return try await router.run(req)
    }
}

fileprivate actor Shared {

    static let `default` = Shared()

    var router: Router?

    func setRouter(_ router: Router) {
        self.router = router
    }
}
