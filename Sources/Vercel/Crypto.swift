//
//  Crypto.swift
//
//
//  Created by Andrew Barba on 2/8/23.
//

import Crypto

public enum Crypto {}

// MARK: - Hashing

extension Crypto {

    public static func hash<T>(_ input: String, using hash: T.Type) -> T.Digest where T: HashFunction {
        return T.hash(data: Data(input.utf8))
    }

    public static func hash<T>(_ input: [UInt8], using hash: T.Type) -> T.Digest where T: HashFunction {
        return T.hash(data: Data(input))
    }

    public static func hash<T>(_ input: Data, using hash: T.Type) -> T.Digest where T: HashFunction {
        return T.hash(data: input)
    }

    public static func sha256(_ input: String) -> SHA256.Digest {
        return hash(input, using: SHA256.self)
    }

    public static func sha256(_ input: [UInt8]) -> SHA256.Digest {
        return hash(input, using: SHA256.self)
    }

    public static func sha256(_ input: Data) -> SHA256.Digest {
        return hash(input, using: SHA256.self)
    }

    public static func sha384(_ input: String) -> SHA384.Digest {
        return hash(input, using: SHA384.self)
    }

    public static func sha384(_ input: [UInt8]) -> SHA384.Digest {
        return hash(input, using: SHA384.self)
    }

    public static func sha384(_ input: Data) -> SHA384.Digest {
        return hash(input, using: SHA384.self)
    }

    public static func sha512(_ input: String) -> SHA512.Digest {
        return hash(input, using: SHA512.self)
    }

    public static func sha512(_ input: [UInt8]) -> SHA512.Digest {
        return hash(input, using: SHA512.self)
    }

    public static func sha512(_ input: Data) -> SHA512.Digest {
        return hash(input, using: SHA512.self)
    }
}

// MARK: - HMAC

extension Crypto {
    public enum Auth {
        public enum Hash {
            case sha256
            case sha384
            case sha512
        }

        public static func code(for input: String, secret: String, using hash: Hash) -> Data {
            let data = Data(input.utf8)
            let key = SymmetricKey(data: Data(secret.utf8))
            switch hash {
            case .sha256:
                return HMAC<SHA256>.authenticationCode(for: data, using: key).data
            case .sha384:
                return HMAC<SHA384>.authenticationCode(for: data, using: key).data
            case .sha512:
                return HMAC<SHA512>.authenticationCode(for: data, using: key).data
            }
        }

        public static func verify(_ input: String, signature: Data, secret: String, using hash: Hash) -> Bool {
            let computed = code(for: input, secret: secret, using: hash)
            return computed.toHexString() == signature.toHexString()
        }
    }
}

// MARK: - ECDSA

extension Crypto {
    public enum ECDSA {
        public enum Algorithm {
            case p256
            case p384
            case p521
        }

        public static func signature(for input: String, secret: String, using algorithm: Algorithm) throws -> Data {
            switch algorithm {
            case .p256:
                let pk = try P256.Signing.PrivateKey(pemRepresentation: secret)
                return try pk.signature(for: Crypto.sha256(input)).rawRepresentation
            case .p384:
                let pk = try P384.Signing.PrivateKey(pemRepresentation: secret)
                return try pk.signature(for: Crypto.sha384(input)).rawRepresentation
            case .p521:
                let pk = try P521.Signing.PrivateKey(pemRepresentation: secret)
                return try pk.signature(for: Crypto.sha512(input)).rawRepresentation
            }
        }

        public static func verify(_ input: String, signature: Data, key: String, using algorithm: Algorithm) throws -> Bool {
            switch algorithm {
            case .p256:
                let publicKey = try P256.Signing.PublicKey(pemRepresentation: key)
                let ecdsaSignature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
                return publicKey.isValidSignature(ecdsaSignature, for: Crypto.sha256(input))
            case .p384:
                let publicKey = try P384.Signing.PublicKey(pemRepresentation: key)
                let ecdsaSignature = try P384.Signing.ECDSASignature(rawRepresentation: signature)
                return publicKey.isValidSignature(ecdsaSignature, for: Crypto.sha384(input))
            case .p521:
                let publicKey = try P521.Signing.PublicKey(pemRepresentation: key)
                let ecdsaSignature = try P521.Signing.ECDSASignature(rawRepresentation: signature)
                return publicKey.isValidSignature(ecdsaSignature, for: Crypto.sha512(input))
            }
        }
    }
}

// MARK: - Utils

extension DataProtocol {
    public var bytes: [UInt8] {
        return .init(self)
    }

    public var data: Data {
        return .init(self)
    }

    public func toHexString() -> String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}

extension Digest {
    public var bytes: [UInt8] {
        return .init(self)
    }

    public var data: Data {
        return .init(self)
    }

    public func toHexString() -> String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}

extension HashedAuthenticationCode {
    public var bytes: [UInt8] {
        return .init(self)
    }

    public var data: Data {
        return .init(self)
    }

    public func toHexString() -> String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}

extension Array where Element == UInt8 {
    public var data: Data {
        return .init(self)
    }

    public func toHexString() -> String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}
