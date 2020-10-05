import XCTest
@testable import Causality

fileprivate struct Message1: Causality.Message {
    let string: String
}
fileprivate struct Message2: Causality.Message {
    let number: Int
}
fileprivate let stringEvent = Causality.Event<Message1>(name: "Foo")
fileprivate let numberEvent = Causality.Event<Message2>(name: "Foo")

class CustomEvent<Message: Causality.Message>: Causality.CustomEvent<Message> {
    let eventId: Int

    init(eventId: Int) {
        self.eventId = eventId
    }
    static func == (lhs: CustomEvent<Message>, rhs: CustomEvent<Message>) -> Bool {
        return lhs.eventId == rhs.eventId
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.eventId)
    }
}


final class CausalityTests: XCTestCase {

    func testThat_SubscriberWillBeCalledOnce_IfDeclaredBeforePublish() {
        let inputValue = "Hello!"
        let expectedValue = inputValue
        var resolvedValue: String?
        var subscriberCount = 0
        let expectedSubscriberCount = 1

        let expectation = XCTestExpectation()
        let event = Causality.Bus(name: "\(#function)")

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

    func testThat_SubscriberWillNotBeCalled_IfDeclaredAfterPublish() {
        let inputValue = "Hello!"
        let expectedValue: String? = nil
        var resolvedValue: String?
        var subscriberCount = 0
        let expectedSubscriberCount = 0

        let expectation = XCTestExpectation()
        let event = Causality.Bus(name: "\(#function)")

        event.publish(event: stringEvent, message: Message1(string: inputValue))
        event.subscribe(stringEvent) { message in

            resolvedValue = message.string
            subscriberCount += 1
        }

        expectation.fulfill()
        self.wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(expectedValue, resolvedValue, "Expected value (\(expectedValue ?? "(nil)")) != Resolved value (\(resolvedValue ?? "(nil)"))")
        XCTAssertEqual(subscriberCount, expectedSubscriberCount, "Expected subscriber to be called exactly \(expectedSubscriberCount) time.  Instead called \(subscriberCount) times")
    }

    func testThat_SubscriberCanUnsubscribe_InHandler() {
        let inputValue = "Hello!"
        let event = Causality.Bus(name: "\(#function)")
        var subscriberCount = 0
        let expectedSubscriberCount = 0

        event.subscribe(stringEvent) { subscriber, message in
            subscriberCount += 1
            subscriber.unsubscribe()
        }

        event.publish(event: stringEvent, message: Message1(string: inputValue))
        event.publish(event: stringEvent, message: Message1(string: inputValue))

        XCTAssertEqual(subscriberCount, 1, "Expected subscriberCount: \(expectedSubscriberCount). Got \(subscriberCount)")
    }

    func testThat_PlainStringMessage_CanBeSent() {
        let inputString = "Hello World!"
        let expectedString = inputString
        var resolvedString: String? = nil

        let event = Causality.Bus(name: "\(#function)")
        let plainStringEvent = Causality.Event<String>(name: "plain String")

        let expectation = XCTestExpectation()

        event.subscribe(plainStringEvent) { (subscription, string) in
            print("Got a string: \(string)")
            resolvedString = string
            expectation.fulfill()
        }
        event.publish(event: plainStringEvent, message: inputString)

        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(expectedString, resolvedString, "Expected: \(expectedString)  Got instead: \(resolvedString ?? "(nil)")")
    }

    func testThat_DynamicAddressingWithIdenticalParameters_IsTreatedIdentically() {
        let inputValues = [ "a", "b", "c", "d" ]
        let expectedValues = [ "b" ]
        var resolvedValues: [String] = []

        let event = Causality.Bus(name: "\(#function)")
        class DynamicEvent<Message: Causality.Message>: Causality.DynamicEvent<Message> {

            let eventId: Int

            init(eventId: Int) {
                self.eventId = eventId
            }
            enum CodingKeys: CodingKey {
                case eventId
            }
            override func encode(to encoder: Encoder) throws {
                try super.encode(to: encoder)
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.eventId, forKey: .eventId)
            }
        }

        let expectation = XCTestExpectation()

        // specifically testing that separate instances of identical types are treated identically
        let event1a = DynamicEvent<Message1>(eventId: 1)
        let event1b = DynamicEvent<Message1>(eventId: 1)
        let event2 = DynamicEvent<Message1>(eventId: 2)
        let event3 = DynamicEvent<Causality.NoMessage>(eventId: 3)

        let subscription = event.subscribe(event1a) { (message) in
            defer {
                expectation.fulfill()
            }

            resolvedValues.append(message.string)
        }

        event.publish(event: event2, message: Message1(string: inputValues[0]))
        event.publish(event: event1b, message: Message1(string: inputValues[1]))
        event.publish(event: event3)

        wait(for: [expectation], timeout: 2)
        subscription.unsubscribe()

        XCTAssertEqual(expectedValues, resolvedValues, "Expected \(expectedValues).  Got: \(resolvedValues)")
    }


    // MARK: - Performance Tests
    func testPerformanceOf_Signal() {
        var didTimeout = false
        self.measure {
            let semaphore = DispatchSemaphore(value: 0)
            semaphore.signal()
            let result = semaphore.wait(timeout: .now()+1)
            if result == .timedOut {
                didTimeout = true
            }
        }
        XCTAssertFalse(didTimeout, "Should not have timed out")
    }

    func testPerformanceOf_SingleEvent() {
        let event = Causality.Bus(name: "\(#function)")
        let semaphore = DispatchSemaphore(value: 0)
        let triggerEvent = Causality.Event<Causality.NoMessage>(name: "Trigger")
        var didTimeout = false

        event.subscribe(triggerEvent) { _ in
            semaphore.signal()
        }
        self.measure {
            event.publish(event: triggerEvent)
            let result = semaphore.wait(timeout: .now()+1)
            if result == .timedOut {
                didTimeout = true
            }
        }
        XCTAssertFalse(didTimeout, "Should not have timed out")
    }

    static var allTests = [
        ( "testThat_SubscriberWillBeCalledOnce_IfDeclaredBeforePublish", testThat_SubscriberWillBeCalledOnce_IfDeclaredBeforePublish ),
        ( "testThat_SubscriberWillNotBeCalled_IfDeclaredAfterPublish", testThat_SubscriberWillNotBeCalled_IfDeclaredAfterPublish ),
        ( "testThat_SubscriberCanUnsubscribe_InHandler", testThat_SubscriberCanUnsubscribe_InHandler ),
        ( "testPerformanceOf_Signal", testPerformanceOf_Signal ),
        ( "testPerformanceOf_SingleEvent", testPerformanceOf_SingleEvent ),
    ]
}
