import XCTest
@testable import Vercel

final class ClaimTests: XCTestCase {
    func testClaimChaining() async throws {
        let claim = Claim(value: [
            "a": [
                "b": [
                    "c": 100
                ]
            ]
        ])
        XCTAssertEqual(claim["a"]["b"]["c"].int, 100)
    }
}
