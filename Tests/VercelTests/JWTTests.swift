import XCTest
@testable import Vercel

private let token =
"""
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2Njk1OTE2MTEsIm5hbWUiOiJKb2huIERvZSIsInN1YiI6IjEyMzQ1Njc4OTAifQ.FUVIl48Ji1mWZa42K1OTG0x_2T0FYOXNACsmeNI2-Kc
"""

final class JWTTests: XCTestCase {

    func testVerifySuccess() throws {
        let jwt = try JWT(token: token)
        try jwt.verify(secret: "your-256-bit-secret")
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
