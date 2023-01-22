import XCTest
@testable import Vercel

final class RequestTests: XCTestCase {
    func testDecode() throws {
        let json = """
        {"method": "GET", "path": "/", "headers": {}}
        """
        let req = try JSONDecoder().decode(Request.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(req.method, .GET)
    }
}
