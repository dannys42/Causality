import XCTest
@testable import SimpleEventBus

struct Message1: SimpleEventMessage {
    let string: String
}
struct Message2: SimpleEventMessage {
    let number: Int
}
let stringEvent = SimpleEvent<Message1>(name: "Foo")
let numberEvent = SimpleEvent<Message2>(name: "Foo")

final class SimpleEventBusTests: XCTestCase {

    func testThat_SubscriberWillBeCalledOnce_IfDeclaredBeforePublish() {
        let inputValue = "Hello!"
        let expectedValue = inputValue
        var resolvedValue: String?
        var subscriberCount = 0
        let expectedSubscriberCount = 0

        let expectation = XCTestExpectation()
        let event = SimpleEventBus(name: "\(#function)")

        event.subscribe(stringEvent) { message in

            resolvedValue = message.string
            subscriberCount += 1
            expectation.fulfill()
        }
        event.publish(event: stringEvent, message: Message1(string: inputValue))

        self.wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(expectedValue, resolvedValue, "Expected value (\(expectedValue)) != Resolved value (\(resolvedValue ?? "(nil)"))")
        XCTAssertEqual(subscriberCount, expectedSubscriberCount, "Expected subscriber to be called exactly \(expectedSubscriberCount) time.  Instead called \(subscriberCount) times")
    }

    func testThat_SubscriberWillNotBeCalledOnce_IfDeclaredAfterPublish() {
        let inputValue = "Hello!"
        let expectedValue: String? = nil
        var resolvedValue: String?
        var subscriberCount = 0
        let expectedSubscriberCount = 0

        let expectation = XCTestExpectation()
        let event = SimpleEventBus(name: "\(#function)")

        event.publish(event: stringEvent, message: Message1(string: inputValue))
        event.subscribe(stringEvent) { message in

            resolvedValue = message.string
            subscriberCount += 1
            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(expectedValue, resolvedValue, "Expected value (\(expectedValue ?? "(nil)")) != Resolved value (\(resolvedValue ?? "(nil)"))")
        XCTAssertEqual(subscriberCount, expectedSubscriberCount, "Expected subscriber to be called exactly \(expectedSubscriberCount) time.  Instead called \(subscriberCount) times")
    }


    static var allTests = [
        ( "testThat_SubscriberWillBeCalledOnce_IfDeclaredBeforePublish", testThat_SubscriberWillBeCalledOnce_IfDeclaredBeforePublish ),
        ( "testThat_SubscriberWillNotBeCalledOnce_IfDeclaredAfterPublish", testThat_SubscriberWillNotBeCalledOnce_IfDeclaredAfterPublish ),
    ]
}
