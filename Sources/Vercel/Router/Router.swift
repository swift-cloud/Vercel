//
//  Router.swift
//  
//
//  Created by Andrew Barba on 1/22/23.
//

import HTTPTypes

public actor Router {

    public typealias Handler = (IncomingRequest, OutgoingResponse) async throws -> OutgoingResponse

    public let prefix: String

    private var middleware: [Handler] = []

    private let router: TrieRouter<Handler>

    public init(prefix path: String = "/") {
        self.prefix = path
        self.router = TrieRouter()
    }

    @discardableResult
    private func add(method: HTTPRequest.Method, path: String, handler: @escaping Handler) -> Self {
        let pathComponents = path.components(separatedBy: "/").filter { $0.isEmpty == false }
        let prefixComponents = prefix.components(separatedBy: "/").filter { $0.isEmpty == false }
        let combinedComponents = [method.rawValue] + prefixComponents + pathComponents
        router.register(handler, at: combinedComponents.map { .init(stringLiteral: $0) })
        return self
    }

    private func handler(for req: inout IncomingRequest) -> Handler? {
        let pathComponents = req.url.pathComponents.dropFirst()
        return router.route(path: [req.method.rawValue] + pathComponents, parameters: &req.pathParameters)
    }
}

extension Router {

    @discardableResult
    public func get(_ path: String, _ handler: @escaping Handler) -> Self {
        add(method: .head, path: path, handler: handler)
        return add(method: .get, path: path, handler: handler)
    }

    @discardableResult
    public func post(_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .post, path: path, handler: handler)
    }

    @discardableResult
    public func put (_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .put, path: path, handler: handler)
    }

    @discardableResult
    public func delete(_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .delete, path: path, handler: handler)
    }

    @discardableResult
    public func options(_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .options, path: path, handler: handler)
    }

    @discardableResult
    public func patch(_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .patch, path: path, handler: handler)
    }

    @discardableResult
    public func head(_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .head, path: path, handler: handler)
    }

    @discardableResult
    public func all(_ path: String, _ handler: @escaping Handler) -> Self {
        let methods: [HTTPRequest.Method] = [.get, .post, .put, .delete, .options, .patch, .head]
        for method in methods {
            add(method: method, path: path, handler: handler)
        }
        return self
    }
}

extension Router {

    @discardableResult
    public func use(_ handler: @escaping Handler) -> Self {
        middleware.append(handler)
        return self
    }
}

extension Router {

    public func run(_ req: IncomingRequest) async throws -> OutgoingResponse {
        // Create base response
        var res = OutgoingResponse(status: .ok)

        // Run all middleware
        for middlewareHandler in middleware {
            res = try await middlewareHandler(req, res)
        }

        // Check if response was already sent
        guard res.didSend == false else {
            return res
        }

        // Create mutable copy if the request
        var req = req

        // Find matching handler
        guard let handler = handler(for: &req) else {
            return res.status(.notFound).send("Not Found: \(req.path)")
        }

        // Run handler
        return try await handler(req, res)
    }
}
