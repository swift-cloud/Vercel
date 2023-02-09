//
//  JWTError.swift
//
//
//  Created by Andrew Barba on 2/6/23.
//

public enum JWTError: Error {
    case invalidToken
    case invalidData
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
        case .invalidToken:
            return "Invalid token"
        case .invalidData:
            return "Invalid data"
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
