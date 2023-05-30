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
        let payload = try JSONDecoder().decode(InvokeEvent.Payload.self, from: json.data(using: .utf8)!)
        let req = Request(payload)
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
        let payload = try JSONDecoder().decode(InvokeEvent.Payload.self, from: json.data(using: .utf8)!)
        let req = Request(payload)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.headers["a"]!.value, "1")
        XCTAssertEqual(req.headers["b"]!.value, "2")
    }

    func testSearchParams() throws {
        let json = """
        {
          "method": "GET",
          "path": "/foo?token=12345",
          "headers": {}
        }
        """
        let payload = try JSONDecoder().decode(InvokeEvent.Payload.self, from: json.data(using: .utf8)!)
        let req = Request(payload)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.searchParams["token"], "12345")
    }

    func testPlainBody() throws {
        let json = """
        {
          "method": "PUT",
          "path": "/",
          "headers": {},
          "body": "hello"
        }
        """
        let payload = try JSONDecoder().decode(InvokeEvent.Payload.self, from: json.data(using: .utf8)!)
        let req = Request(payload)
        XCTAssertEqual(req.body, "hello")
    }

    func testBase64Body() throws {
        let json = """
        {
          "method": "PUT",
          "path": "/",
          "headers": {},
          "body": "/////w==",
          "encoding": "base64"
        }
        """
        let payload = try JSONDecoder().decode(InvokeEvent.Payload.self, from: json.data(using: .utf8)!)
        let req = Request(payload)
        let expectData: [UInt8] = [0xff, 0xff, 0xff, 0xff]
        XCTAssertEqual(req.rawBody, Data(expectData))
        XCTAssertNil(req.body)
    }
}
