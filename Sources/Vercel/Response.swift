//
//  Response.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

public struct Response: Codable, Sendable {
    public var statusCode: HTTPResponseStatus
    public var headers: HTTPHeaders?
    public var body: String?
    public var isBase64Encoded: Bool?
    public var cookies: [String]?

    public var didSend: Bool {
        body != nil
    }

    public init(
        statusCode: HTTPResponseStatus,
        headers: HTTPHeaders? = nil,
        body: String? = nil,
        isBase64Encoded: Bool? = nil,
        cookies: [String]? = nil
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.isBase64Encoded = isBase64Encoded
        self.cookies = cookies
    }

    public func with(
        statusCode: HTTPResponseStatus? = nil,
        headers: HTTPHeaders? = nil,
        body: String? = nil,
        isBase64Encoded: Bool? = nil,
        cookies: [String]? = nil
    ) -> Self {
        return .init(
            statusCode: statusCode ?? self.statusCode,
            headers: headers ?? self.headers,
            body: body ?? self.body,
            isBase64Encoded: isBase64Encoded ?? self.isBase64Encoded,
            cookies: cookies ?? self.cookies
        )
    }
}

// MARK: - Status

extension Response {

    public func status(_ statusCode: HTTPResponseStatus) -> Self {
        return with(statusCode: statusCode)
    }

    public func status(_ statusCode: UInt) -> Self {
        return with(statusCode: .init(code: statusCode))
    }
}

// MARK: - Headers

extension Response {

    public func header(_ key: String) -> String? {
        return headers?[key]?.value
    }

    public func header(_ key: HTTPHeaderKey) -> String? {
        return header(key.rawValue)
    }

    public func header(_ key: String, _ value: String?) -> Self {
        var headers = self.headers ?? [:]
        if let value {
            headers[key] = .init(value)
        } else {
            headers[key] = nil
        }
        return with(headers: headers)
    }

    public func header(_ key: HTTPHeaderKey, _ value: String?) -> Self {
        return header(key.rawValue, value)
    }

    public func contentType(_ value: String) -> Self {
        return header(.contentType, value)
    }

    fileprivate func defaultContentType(_ value: String) -> Self {
        guard header(.contentType) == nil else {
            return self
        }
        return contentType(value)
    }
}

// MARK: - Send

extension Response {

    public func send(_ text: String) -> Self {
        return with(body: text)
    }

    public func send(_ data: Data) -> Self {
        return with(body: data.base64EncodedString(), isBase64Encoded: true)
    }

    public func send(_ bytes: [UInt8]) -> Self {
        return with(body: Data(bytes).base64EncodedString(), isBase64Encoded: true)
    }

    public func send<T>(
        _ value: T,
        encoder: JSONEncoder = .init(),
        contentType: String = "application/json"
    ) throws -> Self where T: Encodable {
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)
        return defaultContentType("application/json").with(body: json)
    }

    public func send(_ jsonObject: [String: Any]) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: jsonObject)
        let json = String(data: data, encoding: .utf8)
        return defaultContentType("application/json").with(body: json)
    }

    public func send(_ jsonArray: [Any]) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: jsonArray)
        let json = String(data: data, encoding: .utf8)
        return defaultContentType("application/json").with(body: json)
    }

    public func send(html text: String) -> Self {
        return defaultContentType("text/html").with(body: text)
    }

    public func send(xml text: String) -> Self {
        return defaultContentType("application/xml").with(body: text)
    }

    public func send() -> Self {
        if body == nil {
            return with(statusCode: .noContent, body: "")
        }
        if let body, body.isEmpty {
            return with(statusCode: .noContent, body: "")
        }
        return self
    }
}

// MARK: - Redirect

extension Response {

    public func redirect(_ location: String, permanent: Bool = false) -> Self {
        return status(permanent ? .permanentRedirect : .temporaryRedirect)
            .header("location", location)
            .send("Redirecting to \(location)")
    }
}

// MARK: - Cors

extension Response {

    public func cors(
        origin: String = "*",
        methods: [HTTPMethod] = [.GET, .HEAD, .PUT, .PATCH, .POST, .DELETE, .QUERY],
        allowHeaders: [String]? = nil,
        allowCredentials: Bool? = nil,
        exposeHeaders: [String]? = nil,
        maxAge: Int = 600
    ) -> Self {
        return header(.accessControlAllowOrigin, origin)
            .header(.accessControlAllowMethods, methods.map { $0.rawValue }.joined(separator: ", "))
            .header(.accessControlAllowHeaders, allowHeaders?.joined(separator: ", ") ?? "*")
            .header(.accessControlAllowCredentials, allowCredentials?.description)
            .header(.accessControlExposeHeaders, exposeHeaders?.joined(separator: ", "))
            .header(.accessControlMaxAge, .init(maxAge))
    }
}

// MARK: - Cookie

extension Response {

    public enum CookieOption {
        public enum SameSite: String {
            case strict = "Strict"
            case lax = "Lax"
            case none = "None"
        }

        // Domain=
        case domain(_ domain: String)

        // Expires=
         case expires(_ date: Date)

        // HttpOnly
        case httpOnly

        // Max-Age=
        case maxAge(_ seconds: TimeInterval)

        // Path=
        case path(_ path: String)

        // SameSite=
        case sameSite(_ value: SameSite)

        // Secure
        case secure

        var value: String {
            switch self {
            case .domain(let domain):
                return "Domain=\(domain)"
            case .expires(let date):
                return "Expires=\(DateFormatter.httpDate.string(from: date))"
            case .httpOnly:
                return "HttpOnly"
            case .maxAge(let seconds):
                return "Max-Age=\(Int(seconds))"
            case .path(let path):
                return "Path=\(path)"
            case .sameSite(let value):
                return "SameSite=\(value.rawValue)"
            case .secure:
                return "Secure"
            }
        }
    }

    public func cookie(
        _ name: String,
        _ value: String,
        _ options: CookieOption...
    ) -> Self {
        return cookie(name, value, options)
    }

    public func cookie(
        _ name: String,
        _ value: String,
        _ options: [CookieOption]
    ) -> Self {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .javascriptURLAllowed) ?? name
        let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .javascriptURLAllowed) ?? value
        let parts = ["\(encodedName)=\(encodedValue)"] + options.map(\.value)
        let cookie = parts.joined(separator: "; ")
        return header(.setCookie, cookie)
    }
}
