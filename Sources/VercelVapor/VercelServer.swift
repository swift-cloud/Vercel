//
//  VercelServer.swift
//  
//
//  Created by Andrew Barba on 8/22/23.
//

import AWSLambdaRuntime
import Vapor
import Vercel

public final class VercelServer: Server {

    private let app: Application

    public init(app: Application) {
        self.app = app
    }

    public var onShutdown: EventLoopFuture<Void> {
        return app.eventLoopGroup.next().makeSucceededVoidFuture()
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
                VercelServer(app: app)
            }
        }
    }
}
