//
//  Response.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

import HTTPTypes

public struct OutgoingResponse: Sendable {
    public var response: HTTPResponse
    
    public var body: String?

    public var encoding: InvokeResponse.Encoding?

    public var didSend: Bool {
        body != nil
    }

    public init(
        status: HTTPResponse.Status = .ok,
        headerFields: HTTPFields = [:],
        body: String? = nil,
        encoding: InvokeResponse.Encoding? = nil
    ) {
        self.response = .init(status: status, headerFields: headerFields)
        self.body = body
        self.encoding = encoding
    }

    public func with(
        status: HTTPResponse.Status? = nil,
        headerFields: HTTPFields? = nil,
        body: String? = nil,
        encoding: InvokeResponse.Encoding? = nil
    ) -> Self {
        return .init(
            status: status ?? self.response.status,
            headerFields: headerFields ?? self.response.headerFields,
            body: body ?? self.body,
            encoding: encoding ?? self.encoding
        )
    }
}

// MARK: - Static Init

extension OutgoingResponse {

    public static func status(_ statusCode: HTTPResponse.Status) -> Self {
        return .init(status: statusCode)
    }

    public static func status(_ status: Int) -> Self {
        return .init(status: .init(code: status))
    }
}

// MARK: - Status

extension OutgoingResponse {

    public func status(_ status: HTTPResponse.Status) -> Self {
        return with(status: status)
    }

    public func status(_ status: Int) -> Self {
        return with(status: .init(code: status))
    }
}

// MARK: - Headers

extension OutgoingResponse {

    public func header(_ key: String) -> String? {
        guard let field = HTTPField.Name(key) else {
            return nil
        }
        return response.headerFields[field]
    }

    public func header(_ field: HTTPField.Name) -> String? {
        return response.headerFields[field]
    }

    public func header(_ key: String, _ value: String?) -> Self {
        guard let field = HTTPField.Name(key) else {
            return self
        }
        var headerFields = response.headerFields
        headerFields[field] = value
        return with(headerFields: headerFields)
    }

    public func header(_ field: HTTPField.Name, _ value: String?) -> Self {
        var headerFields = response.headerFields
        headerFields[field] = value
        return with(headerFields: headerFields)
    }

    public func contentType(_ value: String) -> Self {
        return header(.contentType, value)
    }

    public func cacheControl(maxAge ttl: Int, staleWhileRevalidate swr: Int = 0) -> Self {
        return header(.cacheControl, "s-maxage=\(ttl), stale-while-revalidate=\(swr)")
    }

    fileprivate func defaultContentType(_ value: String) -> Self {
        guard header(.contentType) == nil else {
            return self
        }
        return contentType(value)
    }
}

// MARK: - Send

extension OutgoingResponse {

    public func send(_ text: String) -> Self {
        return with(body: text)
    }

    public func send(_ data: Data) -> Self {
        return with(body: data.base64EncodedString(), encoding: .base64)
    }

    public func send(_ bytes: [UInt8]) -> Self {
        return with(body: Data(bytes).base64EncodedString(), encoding: .base64)
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
            return with(status: .noContent, body: "")
        }
        if let body, body.isEmpty {
            return with(status: .noContent, body: "")
        }
        return self
    }
}

// MARK: - Redirect

extension OutgoingResponse {

    public func redirect(_ location: String, permanent: Bool = false) -> Self {
        return status(permanent ? .permanentRedirect : .temporaryRedirect)
            .header("location", location)
            .send("Redirecting to \(location)")
    }
}

// MARK: - Cors

extension OutgoingResponse {

    public func cors(
        origin: String = "*",
        methods: [HTTPRequest.Method] = [.get, .head, .put, .patch, .post, .delete],
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

extension OutgoingResponse {

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
