import XCTest
@testable import Vercel

final class RequestTests: XCTestCase {
    func testSimpleDecode() throws {
        let json = """
        {
          "method": "GET",
          "path": "/",
          "headers": {}
        }
        """
        let req = try JSONDecoder().decode(Request.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(req.method, .GET)
    }

    func testMultiValueHeaderDecode() throws {
        let json = """
        {
          "method": "GET",
          "path": "/",
          "headers": {
            "a": "1",
            "b": ["2", "3"]
          }
        }
        """
        let req = try JSONDecoder().decode(Request.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.headers["a"]!.value, "1")
        XCTAssertEqual(req.headers["b"]!.value, "2")
    }
}
