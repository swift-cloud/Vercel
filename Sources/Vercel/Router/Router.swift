//
//  Router.swift
//  
//
//  Created by Andrew Barba on 1/22/23.
//

public final class Router {

    public typealias Handler = (Request, Response) async throws -> Response

    public let prefix: String

    private var middleware: [Handler] = []

    private let router: TrieRouter<Handler>

    public init(prefix path: String = "/") {
        self.prefix = path
        self.router = TrieRouter()
    }

    @discardableResult
    private func add(method: HTTPMethod, path: String, handler: @escaping Handler) -> Self {
        let pathComponents = path.components(separatedBy: "/").filter { $0.isEmpty == false }
        let prefixComponents = prefix.components(separatedBy: "/").filter { $0.isEmpty == false }
        let combinedComponents = [method.rawValue] + prefixComponents + pathComponents
        router.register(handler, at: combinedComponents.map { .init(stringLiteral: $0) })
        return self
    }

    private func handler(for req: inout Request) -> Handler? {
        let pathComponents = req.url.pathComponents.dropFirst()
        req._pathParams = req._pathParams ?? .init()
        return router.route(path: [req.method.rawValue] + pathComponents, parameters: &req.pathParams)
    }
}

extension Router {

    @discardableResult
    public func get(_ path: String, _ handler: @escaping Handler) -> Self {
        add(method: .HEAD, path: path, handler: handler)
        return add(method: .GET, path: path, handler: handler)
    }

    @discardableResult
    public func post(_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .POST, path: path, handler: handler)
    }

    @discardableResult
    public func put (_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .PUT, path: path, handler: handler)
    }

    @discardableResult
    public func delete(_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .DELETE, path: path, handler: handler)
    }

    @discardableResult
    public func options(_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .OPTIONS, path: path, handler: handler)
    }

    @discardableResult
    public func patch(_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .PATCH, path: path, handler: handler)
    }

    @discardableResult
    public func head(_ path: String, _ handler: @escaping Handler) -> Self {
        return add(method: .HEAD, path: path, handler: handler)
    }

    @discardableResult
    public func all(_ path: String, _ handler: @escaping Handler) -> Self {
        for method in HTTPMethod.allCases {
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

    public func run(_ req: Request) async throws -> Response {
        // Create base response
        var res = Response(statusCode: .ok)

        // Run all middleware
        for middlewareHandler in middleware {
            res = try await middlewareHandler(req, res)
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
