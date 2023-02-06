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
        try jwt.verify(secret: "your-256-bit-secret", expiration: false)
    }

    func testVerifyFanoutSuccess() throws {
        let jwt = try JWT(token: fanoutToken)
        try jwt.verify(secret: fanoutPublicKey, algorithm: .es256, expiration: false)
    }

    func testVerifyFailure() throws {
        let jwt = try JWT(token: token)
        try XCTAssertThrowsError(jwt.verify(secret: "bogus-secret"))
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
}
