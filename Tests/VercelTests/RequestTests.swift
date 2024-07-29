import AWSLambdaRuntime
import XCTest

@testable import Vercel

let context = LambdaContext.__forTestsOnly(
    requestID: "",
    traceID: "",
    invokedFunctionARN: "",
    timeout: .seconds(10),
    logger: .init(label: ""),
    eventLoop: .singletonMultiThreadedEventLoopGroup.next()
)

final class RequestTests: XCTestCase {
    func testSimpleDecode() throws {
        let json = """
            {
              "method": "GET",
              "path": "/",
              "headers": {}
            }
            """
        let payload = try JSONDecoder().decode(
            InvokeEvent.Payload.self, from: json.data(using: .utf8)!)
        let req = IncomingRequest(payload, in: context)
        XCTAssertEqual(req.method, .get)
    }

    func testMultiValueHeaderDecode() throws {
        let json = """
            {
              "method": "GET",
              "path": "/",
              "headers": {
                "accept": "1",
                "content-type": ["2", "3"]
              }
            }
            """
        let payload = try JSONDecoder().decode(
            InvokeEvent.Payload.self, from: json.data(using: .utf8)!)
        let req = IncomingRequest(payload, in: context)
        XCTAssertEqual(req.method, .get)
        XCTAssertEqual(req.headerFields[.accept], "1")
        XCTAssertEqual(req.headerFields[.contentType], "2")
    }

    func testSearchParams() throws {
        let json = """
            {
              "method": "GET",
              "path": "/foo?token=12345",
              "headers": {}
            }
            """
        let payload = try JSONDecoder().decode(
            InvokeEvent.Payload.self, from: json.data(using: .utf8)!)
        let req = IncomingRequest(payload, in: context)
        XCTAssertEqual(req.method, .get)
        XCTAssertEqual(req.searchParams["token"], "12345")
    }

    func testPlainBody() async throws {
        let json = """
            {
              "method": "PUT",
              "path": "/",
              "headers": {},
              "body": "hello"
            }
            """
        let payload = try JSONDecoder().decode(
            InvokeEvent.Payload.self, from: json.data(using: .utf8)!)
        let req = IncomingRequest(payload, in: context)
        let text = try await req.body?.text()
        XCTAssertEqual(text, "hello")
    }

    func testBase64Body() async throws {
        let json = """
            {
              "method": "PUT",
              "path": "/",
              "headers": {},
              "body": "/////w==",
              "encoding": "base64"
            }
            """
        let payload = try JSONDecoder().decode(
            InvokeEvent.Payload.self, from: json.data(using: .utf8)!)
        let req = IncomingRequest(payload, in: context)
        let data = try await req.body?.bytes()
        XCTAssertEqual(data, [0xff, 0xff, 0xff, 0xff])
    }
}
