import XCTest
@testable import Vercel

private let _id = "ecfg_12345678"

final class EdgeConfigTests: XCTestCase {
    func testParseId() throws {
        let id = try EdgeConfig.parseConfigID(_id)
        XCTAssertEqual(id, _id)
    }

    func testParseUrl() throws {
        let id = try EdgeConfig.parseConfigID("https://edge-config.vercel.com/\(_id)?token=12345")
        XCTAssertEqual(id, _id)
    }

    func testParseEnvVar() throws {
        let id = try EdgeConfig.parseConfigID("EDGE_CONFIG")
        XCTAssertEqual(id, _id)
    }

    func testBadInput() throws {
        XCTAssertThrowsError(try EdgeConfig.parseConfigID("12345")) {
            XCTAssertEqual($0 as! EdgeConfigError, EdgeConfigError.invalidConnection)
        }
    }
}
