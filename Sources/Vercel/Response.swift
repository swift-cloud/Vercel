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

extension Response {

    public func status(_ statusCode: HTTPResponseStatus) -> Self {
        return with(statusCode: statusCode)
    }
}

extension Response {

    public func send(_ text: String) -> Self {
        return with(body: text)
    }
}
