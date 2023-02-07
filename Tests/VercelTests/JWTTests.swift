import XCTest
@testable import Vercel

private let token =
"""
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2Njk1OTE2MTEsIm5hbWUiOiJKb2huIERvZSIsInN1YiI6IjEyMzQ1Njc4OTAifQ.FUVIl48Ji1mWZa42K1OTG0x_2T0FYOXNACsmeNI2-Kc
"""

private let fanoutToken =
"""
eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiJ9.eyJleHAiOjE2NzUzNjU0MjgsImlzcyI6ImZhc3RseSJ9.QL2Pm1JnXV/vAYK7ijeD4U1CBjOTLihNMDZ+qfvjkKOTUiK1jyxGEwjZfeApijRaOtQT8fVkdPnKjF+tBiUzkA
"""

public let fanoutPublicKey =
    """
    -----BEGIN PUBLIC KEY-----
    MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAECKo5A1ebyFcnmVV8SE5On+8G81Jy
    BjSvcrx4VLetWCjuDAmppTo3xM/zz763COTCgHfp/6lPdCyYjjqc+GM7sw==
    -----END PUBLIC KEY-----
    """

final class JWTTests: XCTestCase {

    func testVerifySuccess() throws {
        let jwt = try JWT(token: token)
        try jwt.verify(key: "your-256-bit-secret", expiration: false)
    }

    func testVerifyFanoutSuccess() throws {
        let jwt = try JWT(token: fanoutToken)
        try jwt.verify(key: fanoutPublicKey, expiration: false)
    }

    func testVerifyFailure() throws {
        let jwt = try JWT(token: token)
        try XCTAssertThrowsError(jwt.verify(key: "bogus-secret"))
    }

    func testSubject() throws {
        let jwt = try JWT(token: token)
        XCTAssertNotNil(jwt.subject)
        XCTAssertEqual(jwt.subject, "1234567890")
    }

    func testClaim() throws {
        let jwt = try JWT(token: token)
        XCTAssertNotNil(jwt["name"].string)
        XCTAssertEqual(jwt["name"].string, "John Doe")
    }

    func testCreate() throws {
        let jwt = try JWT(
            claims: ["name": "John Doe"],
            secret: "your-256-bit-secret",
            issuedAt: Date(timeIntervalSince1970: 1669591611),
            subject: "1234567890"
        )
        XCTAssertEqual(jwt.token, token)
    }

    func testES256() throws {
        let publicKey = """
        -----BEGIN PUBLIC KEY-----
        MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEEVs/o5+uQbTjL3chynL4wXgUg2R9
        q9UU8I5mEovUf86QZ7kOBIjJwqnzD1omageEHWwHdBO6B+dFabmdT9POxg==
        -----END PUBLIC KEY-----
        """
        let privateKey = """
        -----BEGIN PRIVATE KEY-----
        MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
        OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
        1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
        -----END PRIVATE KEY-----
        """
        let jwt1 = try JWT(
            claims: ["name": "John Doe"],
            secret: privateKey,
            algorithm: .es256,
            issuedAt: Date(timeIntervalSince1970: 1669591611),
            subject: "1234567890"
        )
        let jwt2 = try JWT(token: jwt1.token)
        try jwt2.verify(key: publicKey, expiration: false)
    }
}
