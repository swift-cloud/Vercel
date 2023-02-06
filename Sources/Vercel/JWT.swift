//
//  JWT.swift
//
//
//  Created by Andrew Barba on 1/22/23.
//

import Crypto

public struct JWT: Sendable {

    public let token: String

    public let header: [String: Sendable]

    public let payload: [String: Sendable]

    public let signature: Data

    public func claim(name: String) -> Claim {
        return .init(payload[name])
    }

    public subscript(key: String) -> Claim {
        return claim(name: key)
    }

    public init(token: String) throws {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            throw JWTError.invalidToken
        }
        self.header = try decodeJWTPart(parts[0])
        self.payload = try decodeJWTPart(parts[1])
        self.signature = try base64UrlDecode(parts[2])
        self.token = token
    }

    public init(
        claims: [String: Any],
        secret: String,
        algorithm: Algorithm = .hs256,
        issuedAt: Date = .init(),
        expiresAt: Date? = nil,
        issuer: String? = nil,
        subject: String? = nil,
        identifier: String? = nil
    ) throws {
        let header: [String: Any] = [
            "alg": algorithm.rawValue,
            "typ": "JWT"
        ]

        var properties: [String: Any] = [
            "iat": floor(issuedAt.timeIntervalSince1970)
        ]

        if let expiresAt {
            properties["exp"] = ceil(expiresAt.timeIntervalSince1970)
        }

        if let subject {
            properties["sub"] = subject
        }

        if let issuer {
            properties["iss"] = issuer
        }

        if let identifier {
            properties["jti"] = identifier
        }

        let payload = claims.merging(properties, uniquingKeysWith: { $1 })

        let _header = try encodeJWTPart(header)

        let _payload = try encodeJWTPart(payload)

        let input = "\(_header).\(_payload)"

        let signature = try hmacSignature(input, key: secret, using: algorithm)

        let _signature = try base64UrlEncode(signature)

        self.header = header
        self.payload = payload
        self.signature = signature
        self.token = "\(_header).\(_payload).\(_signature)"
    }
}

extension JWT {

    public var expiresAt: Date? {
        claim(name: "exp").date
    }

    public var issuer: String? {
        claim(name: "iss").string
    }

    public var subject: String? {
        claim(name: "sub").string
    }

    public var audience: [String]? {
        claim(name: "aud").array
    }

    public var issuedAt: Date? {
        claim(name: "iat").date
    }

    public var notBefore: Date? {
        claim(name: "nbf").date
    }

    public var identifier: String? {
        claim(name: "jti").string
    }

    public var expired: Bool {
        guard let expiresAt = self.expiresAt else {
            return false
        }
        return Date() > expiresAt
    }
}

extension JWT {

    @discardableResult
    public func verify(
        secret: String,
        algorithm: Algorithm = .hs256,
        issuer: String? = nil,
        subject: String? = nil,
        expiration: Bool = true
    ) throws -> Self {
        // Build input
        let input = token.components(separatedBy: ".").prefix(2).joined(separator: ".")

        // Verify the signature
        try verifySignature(input, signature: signature, key: secret, using: algorithm)

        // Ensure the jwt is not expired
        if expiration, expired == false {
            throw JWTError.expiredToken
        }

        // Check for a matching issuer
        if let issuer, issuer != self.issuer {
            throw JWTError.invalidIssuer
        }

        // Check for a matching subject
        if let subject, subject != self.subject {
            throw JWTError.invalidSubject
        }

        return self
    }
}

extension JWT {
    public enum Algorithm: String {
        case hs256 = "HS256"
        case hs384 = "HS384"
        case hs512 = "HS512"
        case es256 = "ES256"
    }
}

public enum JWTError: Error {
    case invalidInputData
    case invalidToken
    case invalidBase64URL
    case invalidJSON
    case invalidSignature
    case invalidIssuer
    case invalidSubject
    case expiredToken
    case unsupportedAlgorithm
}

extension JWTError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .invalidInputData:
            return "Invalid input data"
        case .invalidToken:
            return "Invalid token"
        case .invalidBase64URL:
            return "Invalid base64 URL"
        case .invalidJSON:
            return "Invalid JSON"
        case .invalidSignature:
            return "Signatures do not match"
        case .invalidIssuer:
            return "Issuers do not match"
        case .invalidSubject:
            return "Subjects do not match"
        case .expiredToken:
            return "Expired token"
        case .unsupportedAlgorithm:
            return "Unsupported algorithm"
        }
    }
}

extension Data {
    internal func toHexString() -> String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}

private func decodeJWTPart(_ value: String) throws -> [String: Any] {
    let bodyData = try base64UrlDecode(value)
    guard let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any] else {
        throw JWTError.invalidJSON
    }
    return json
}

private func encodeJWTPart(_ value: [String: Any]) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    return try base64UrlEncode(data)
}

private func hmacSignature(_ input: String, key: String, using algorithm: JWT.Algorithm) throws -> Data {
    guard let inputData = input.data(using: .utf8) else {
        throw JWTError.invalidInputData
    }
    guard let keyData = key.data(using: .utf8) else {
        throw JWTError.invalidInputData
    }
    switch algorithm {
    case .hs256:
        return .init(HMAC<SHA256>.authenticationCode(for: inputData, using: .init(data: keyData)))
    case .hs384:
        return .init(HMAC<SHA384>.authenticationCode(for: inputData, using: .init(data: keyData)))
    case .hs512:
        return .init(HMAC<SHA512>.authenticationCode(for: inputData, using: .init(data: keyData)))
    case .es256:
        throw JWTError.unsupportedAlgorithm
    }
}

private func verifySignature(_ input: String, signature: Data, key: String, using algorithm: JWT.Algorithm) throws {
    switch algorithm {
    case .es256:
        try verifyECDSASignature(input, signature: signature, key: key, using: algorithm)
    default:
        try verifyHMACSignature(input, signature: signature, key: key, using: algorithm)
    }
}

private func verifyHMACSignature(_ input: String, signature: Data, key: String, using algorithm: JWT.Algorithm) throws {
    // Compute signature based on secret
    let computedSignature = try hmacSignature(input, key: key, using: algorithm).toHexString()

    // Ensure the signatures match
    guard signature.toHexString() == computedSignature else {
        throw JWTError.invalidSignature
    }
}

private func verifyECDSASignature(_ input: String, signature: Data, key: String, using algorithm: JWT.Algorithm) throws {
    let publicKey = try P256.Signing.PublicKey(pemRepresentation: key)
    let ecdsaSignature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
    let verified = publicKey.isValidSignature(ecdsaSignature, for: sha256(input))
    guard verified else {
        throw JWTError.invalidSignature
    }
}

private func base64UrlDecode(_ value: String) throws -> Data {
    var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 += padding
    }
    guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {
        throw JWTError.invalidBase64URL
    }
    return data
}

private func base64UrlEncode(_ value: Data) throws -> String {
    return value
        .base64EncodedString()
        .trimmingCharacters(in: ["="])
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
}

private func sha256(_ input: String) -> SHA256.Digest {
    let data = input.data(using: .utf8) ?? .init()
    var hash = SHA256()
    hash.update(data: data)
    return hash.finalize()
}
