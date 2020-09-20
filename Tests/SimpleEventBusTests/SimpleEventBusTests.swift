import XCTest
@testable import SimpleEventBus

final class SimpleEventBusTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SimpleEventBus().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
