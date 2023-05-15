//
//  Types.swift
//  
//
//  Created by Andrew Barba on 1/21/23.
//

public enum HTTPMethod: String, CaseIterable, Sendable, Codable {
    case GET
    case HEAD
    case POST
    case PUT
    case DELETE
    case CONNECT
    case OPTIONS
    case TRACE
    case PATCH
    case QUERY
}

public typealias HTTPHeaders = [String: HTTPHeaderValue]

public struct HTTPHeaderValue: Codable, Sendable {

    public let values: [String]

    public var value: String {
        values[0]
    }

    public init(_ value: String) {
        self.values = [value]
    }

    public init(_ values: [String]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let values = try? container.decode([String].self) {
            self.values = values
            return
        }
        if let value = try? container.decode(String.self) {
            self.values = [value]
            return
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Failed to decode HTTP header value")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

public enum HTTPHeaderKey: String, Sendable {
    case accept = "accept"
    case acceptCharset = "accept-charset"
    case acceptEncoding = "accept-encoding"
    case acceptLanguage = "accept-language"
    case acceptRanges = "accept-ranges"
    case accessControlAllowCredentials = "access-control-allow-credentials"
    case accessControlAllowHeaders = "access-control-allow-headers"
    case accessControlAllowMethods = "access-control-allow-methods"
    case accessControlAllowOrigin = "access-control-allow-origin"
    case accessControlExposeHeaders = "access-control-expose-headers"
    case accessControlMaxAge = "access-control-max-age"
    case altSvc = "alt-svc"
    case age = "age"
    case authorization = "authorization"
    case cacheControl = "cache-control"
    case cdnCacheControl = "cdn-cache-control"
    case connection = "connection"
    case contentDisposition = "content-disposition"
    case contentEncoding = "content-encoding"
    case contentLanguage = "content-language"
    case contentLength = "content-length"
    case contentRange = "content-range"
    case contentSecurityPolicy = "content-security-policy"
    case contentType = "content-type"
    case cookie = "cookie"
    case crossOriginResourcePolicy = "cross-origin-resource-policy"
    case date = "date"
    case etag = "etag"
    case expires = "expires"
    case fastlyCacheKey = "fastly-xqd-cache-key"
    case forwarded = "forwarded"
    case from = "from"
    case host = "host"
    case keepAlive = "keep-alive"
    case lastModified = "last-modified"
    case link = "link"
    case location = "location"
    case pragma = "pragma"
    case range = "range"
    case referer = "referer"
    case refererPolicy = "referer-policy"
    case server = "server"
    case setCookie = "set-cookie"
    case surrogateControl = "surrogate-control"
    case surrogateKey = "surrogate-key"
    case trailer = "trailer"
    case transferEncoding = "transfer-encoding"
    case upgrade = "upgrade"
    case userAgent = "user-agent"
    case vary = "vary"
    case vercelCdnCacheControl = "vercel-cdn-cache-control"
    case via = "via"
    case xCache = "x-cache"
    case xCacheHits = "x-cache-hits"
    case xCompressHint = "x-compress-hint"
    case xVercelForwardedFor = "x-vercel-forwarded-for"
    case xVercelId = "x-vercel-id"

    public var stringValue: String {
        rawValue
    }
}

public enum HTTPStatus: Int, Sendable {

    // Informational
    case `continue` = 100
    case switchingProtocols = 101
    case processing = 102

    // Success
    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    case multiStatus = 207
    case alreadyReported = 208
    case imUsed = 209

    // Redirection
    case multipleChoices = 300
    case movedPermanently = 301
    case found = 302
    case seeOther = 303
    case notModified = 304
    case useProxy = 305
    case switchProxy = 306
    case temporaryRedirect = 307
    case permanentRedirect = 308

    // Client error
    case badRequest = 400
    case unauthorised = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case requestEntityTooLarge = 413
    case requestURITooLong = 414
    case unsupportedMediaType = 415
    case requestedRangeNotSatisfiable = 416
    case expectationFailed = 417
    case iamATeapot = 418
    case authenticationTimeout = 419
    case methodFailureSpringFramework = 420
    case enhanceYourCalmTwitter = 4200
    case unprocessableEntity = 422
    case locked = 423
    case failedDependency = 424
    case methodFailureWebDaw = 4240
    case unorderedCollection = 425
    case upgradeRequired = 426
    case preconditionRequired = 428
    case tooManyRequests = 429
    case requestHeaderFieldsTooLarge = 431
    case noResponseNginx = 444
    case retryWithMicrosoft = 449
    case blockedByWindowsParentalControls = 450
    case redirectMicrosoft = 451
    case unavailableForLegalReasons = 4510
    case requestHeaderTooLargeNginx = 494
    case certErrorNginx = 495
    case noCertNginx = 496
    case httpToHttpsNginx = 497
    case clientClosedRequestNginx = 499

    // Server error
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
    case variantAlsoNegotiates = 506
    case insufficientStorage = 507
    case loopDetected = 508
    case bandwidthLimitExceeded = 509
    case notExtended = 510
    case networkAuthenticationRequired = 511
    case connectionTimedOut = 522
    case networkReadTimeoutErrorUnknown = 598
    case networkConnectTimeoutErrorUnknown = 599
}

public struct HTTPResponseStatus: Sendable {
    public let code: UInt
    public let reasonPhrase: String?

    public init(code: UInt, reasonPhrase: String? = nil) {
        self.code = code
        self.reasonPhrase = reasonPhrase
    }

    public static var `continue`: HTTPResponseStatus { HTTPResponseStatus(code: 100) }
    public static var switchingProtocols: HTTPResponseStatus { HTTPResponseStatus(code: 101) }
    public static var processing: HTTPResponseStatus { HTTPResponseStatus(code: 102) }
    public static var earlyHints: HTTPResponseStatus { HTTPResponseStatus(code: 103) }

    public static var ok: HTTPResponseStatus { HTTPResponseStatus(code: 200) }
    public static var created: HTTPResponseStatus { HTTPResponseStatus(code: 201) }
    public static var accepted: HTTPResponseStatus { HTTPResponseStatus(code: 202) }
    public static var nonAuthoritativeInformation: HTTPResponseStatus { HTTPResponseStatus(code: 203) }
    public static var noContent: HTTPResponseStatus { HTTPResponseStatus(code: 204) }
    public static var resetContent: HTTPResponseStatus { HTTPResponseStatus(code: 205) }
    public static var partialContent: HTTPResponseStatus { HTTPResponseStatus(code: 206) }
    public static var multiStatus: HTTPResponseStatus { HTTPResponseStatus(code: 207) }
    public static var alreadyReported: HTTPResponseStatus { HTTPResponseStatus(code: 208) }
    public static var imUsed: HTTPResponseStatus { HTTPResponseStatus(code: 226) }

    public static var multipleChoices: HTTPResponseStatus { HTTPResponseStatus(code: 300) }
    public static var movedPermanently: HTTPResponseStatus { HTTPResponseStatus(code: 301) }
    public static var found: HTTPResponseStatus { HTTPResponseStatus(code: 302) }
    public static var seeOther: HTTPResponseStatus { HTTPResponseStatus(code: 303) }
    public static var notModified: HTTPResponseStatus { HTTPResponseStatus(code: 304) }
    public static var useProxy: HTTPResponseStatus { HTTPResponseStatus(code: 305) }
    public static var temporaryRedirect: HTTPResponseStatus { HTTPResponseStatus(code: 307) }
    public static var permanentRedirect: HTTPResponseStatus { HTTPResponseStatus(code: 308) }

    public static var badRequest: HTTPResponseStatus { HTTPResponseStatus(code: 400) }
    public static var unauthorized: HTTPResponseStatus { HTTPResponseStatus(code: 401) }
    public static var paymentRequired: HTTPResponseStatus { HTTPResponseStatus(code: 402) }
    public static var forbidden: HTTPResponseStatus { HTTPResponseStatus(code: 403) }
    public static var notFound: HTTPResponseStatus { HTTPResponseStatus(code: 404) }
    public static var methodNotAllowed: HTTPResponseStatus { HTTPResponseStatus(code: 405) }
    public static var notAcceptable: HTTPResponseStatus { HTTPResponseStatus(code: 406) }
    public static var proxyAuthenticationRequired: HTTPResponseStatus { HTTPResponseStatus(code: 407) }
    public static var requestTimeout: HTTPResponseStatus { HTTPResponseStatus(code: 408) }
    public static var conflict: HTTPResponseStatus { HTTPResponseStatus(code: 409) }
    public static var gone: HTTPResponseStatus { HTTPResponseStatus(code: 410) }
    public static var lengthRequired: HTTPResponseStatus { HTTPResponseStatus(code: 411) }
    public static var preconditionFailed: HTTPResponseStatus { HTTPResponseStatus(code: 412) }
    public static var payloadTooLarge: HTTPResponseStatus { HTTPResponseStatus(code: 413) }
    public static var uriTooLong: HTTPResponseStatus { HTTPResponseStatus(code: 414) }
    public static var unsupportedMediaType: HTTPResponseStatus { HTTPResponseStatus(code: 415) }
    public static var rangeNotSatisfiable: HTTPResponseStatus { HTTPResponseStatus(code: 416) }
    public static var expectationFailed: HTTPResponseStatus { HTTPResponseStatus(code: 417) }
    public static var imATeapot: HTTPResponseStatus { HTTPResponseStatus(code: 418) }
    public static var misdirectedRequest: HTTPResponseStatus { HTTPResponseStatus(code: 421) }
    public static var unprocessableEntity: HTTPResponseStatus { HTTPResponseStatus(code: 422) }
    public static var locked: HTTPResponseStatus { HTTPResponseStatus(code: 423) }
    public static var failedDependency: HTTPResponseStatus { HTTPResponseStatus(code: 424) }
    public static var upgradeRequired: HTTPResponseStatus { HTTPResponseStatus(code: 426) }
    public static var preconditionRequired: HTTPResponseStatus { HTTPResponseStatus(code: 428) }
    public static var tooManyRequests: HTTPResponseStatus { HTTPResponseStatus(code: 429) }
    public static var requestHeaderFieldsTooLarge: HTTPResponseStatus { HTTPResponseStatus(code: 431) }
    public static var unavailableForLegalReasons: HTTPResponseStatus { HTTPResponseStatus(code: 451) }

    public static var internalServerError: HTTPResponseStatus { HTTPResponseStatus(code: 500) }
    public static var notImplemented: HTTPResponseStatus { HTTPResponseStatus(code: 501) }
    public static var badGateway: HTTPResponseStatus { HTTPResponseStatus(code: 502) }
    public static var serviceUnavailable: HTTPResponseStatus { HTTPResponseStatus(code: 503) }
    public static var gatewayTimeout: HTTPResponseStatus { HTTPResponseStatus(code: 504) }
    public static var httpVersionNotSupported: HTTPResponseStatus { HTTPResponseStatus(code: 505) }
    public static var variantAlsoNegotiates: HTTPResponseStatus { HTTPResponseStatus(code: 506) }
    public static var insufficientStorage: HTTPResponseStatus { HTTPResponseStatus(code: 507) }
    public static var loopDetected: HTTPResponseStatus { HTTPResponseStatus(code: 508) }
    public static var notExtended: HTTPResponseStatus { HTTPResponseStatus(code: 510) }
    public static var networkAuthenticationRequired: HTTPResponseStatus { HTTPResponseStatus(code: 511) }
}

extension HTTPResponseStatus: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.code == rhs.code
    }
}

extension HTTPResponseStatus: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.code = try container.decode(UInt.self)
        self.reasonPhrase = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.code)
    }
}
