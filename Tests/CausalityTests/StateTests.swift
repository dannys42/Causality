//
//  StateTests.swift
//  
//
//  Created by Danny Sung on 09/28/2020.
//

import Foundation
import XCTest
@testable import Causality

fileprivate struct StringState: Causality.StateValue {
    let string: String
}
fileprivate struct NumberState: Causality.StateValue {
    let number: Int
}
fileprivate let InterestingString = Causality.State<StringState>(name: "Foo")
fileprivate let FunNumber = Causality.State<NumberState>(name: "Foo")

final class StateTests: XCTestCase {

    func testThat_InitialState_DoesNotExist() {
        let bus = Causality.Bus(name: "\(#function)")

        let hasState = bus.hasState(InterestingString)
        let state = bus.getState(InterestingString)

        XCTAssertFalse(hasState, "Expect hasState == false on initialization")
        XCTAssertNil(state, "Expect getState == nil on initialization ")
    }

    func testThat_StateExists_AfterPublish() {
        let inputValue = StringState(string: "Hello world!")
        let expectedValue = inputValue
        let resolvedValue: StringState?
        let bus = Causality.Bus(name: "\(#function)")

        bus.set(state: InterestingString, value: inputValue)

        let hasState = bus.hasState(InterestingString)
        resolvedValue = bus.getState(InterestingString)

        XCTAssertTrue(hasState, "Expect hasState == true on initialization")
        XCTAssertEqual(resolvedValue, expectedValue, "Expect getState == \(expectedValue)")
    }

    func testThat_StateHandlerNotCalled_BeforeFirstPublish() {
        let bus = Causality.Bus(name: "\(#function)")
        var didCallHandler = false
        let g = DispatchGroup()

        g.enter()
        _ = bus.subscribe(InterestingString) { _ in
            defer { g.leave() }

            didCallHandler = true
        }

        let result = g.wait(timeout: DispatchTime.now()+2)

        XCTAssertEqual(result, .timedOut, "Expected timeout")
        XCTAssertFalse(didCallHandler, "Expected handler to not be called")
    }

    func testThat_StateHandlerIsCalled_IfDeclaredAfterPublish() {
        let inputValue = StringState(string: "Hello world!")
        let expectedValue = inputValue
        var resolvedValue: StringState?

        let bus = Causality.Bus(name: "\(#function)")
        let g = DispatchGroup()

        bus.set(state: InterestingString, value: inputValue)

        g.enter()
        _ = bus.subscribe(InterestingString) { state in
            defer { g.leave() }

            resolvedValue = state
        }

        let result = g.wait(timeout: DispatchTime.now()+2)

        XCTAssertEqual(result, .success, "No timeout expected")
        XCTAssertEqual(resolvedValue, expectedValue, "Handler to get state \(expectedValue).  Instead got: \(String(describing: resolvedValue))")
    }

    func testThat_StateHandlerIsCalled_IfDeclaredBeforePublish() {
        let inputValue = StringState(string: "Hello world!")
        let expectedValue = inputValue
        var resolvedValue: StringState?

        let bus = Causality.Bus(name: "\(#function)")
        let g = DispatchGroup()

        g.enter()
        _ = bus.subscribe(InterestingString) { state in
            defer { g.leave() }

            resolvedValue = state
        }

        bus.set(state: InterestingString, value: inputValue)

        let result = g.wait(timeout: DispatchTime.now()+2)

        XCTAssertEqual(result, .success, "No timeout expected")
        XCTAssertEqual(resolvedValue, expectedValue, "Expected handler to get state \(expectedValue).  Instead got: \(String(describing: resolvedValue))")
    }

    func testThat_StateHandlerIsCalledOnce_WhenPublishingSameValue() {
        let expectedStateChangeCount = 1
        var resolvedStateChangeCount = 0
        let stateValue = StringState(string: "Hello world!")

        let bus = Causality.Bus(name: "\(#function)")
        let g = DispatchGroup()

        bus.set(state: InterestingString, value: stateValue)

        g.enter()
        _ = bus.subscribe(InterestingString) { state in
            defer { g.leave() }

            resolvedStateChangeCount += 1
        }

        bus.set(state: InterestingString, value: stateValue)

        let result = g.wait(timeout: DispatchTime.now()+2)

        XCTAssertEqual(result, .success, "No timeout expected")
        XCTAssertEqual(resolvedStateChangeCount, expectedStateChangeCount, "Expected count: \(expectedStateChangeCount).  Instead got: \(resolvedStateChangeCount)")
    }

    func testThat_StateHandlerIsCalledOnPublish_WhenPublishingDifferentValues() {
        let expectedStateChangeCount = 2
        var resolvedStateChangeCount = 0
        let stateValue1 = StringState(string: "Hello world!")
        let stateValue2 = StringState(string: "Goodbye cruel world.")

        let bus = Causality.Bus(name: "\(#function)")

        _ = bus.subscribe(InterestingString) { state in
            resolvedStateChangeCount += 1
        }

        bus.set(state: InterestingString, value: stateValue1)
        bus.set(state: InterestingString, value: stateValue2)

        sleep(1)

        XCTAssertEqual(resolvedStateChangeCount, expectedStateChangeCount, "Expected count: \(expectedStateChangeCount).  Instead got: \(resolvedStateChangeCount)")
    }

    func testThat_DynamicAddressingWithIdenticalParameters_IsTreatedIdentically_ForPushAfterSubscribe() {
        let inputValues = [1:"a", 2:"b"]
        let expectedStateValues = ["a"]
        var resolvedStateValues: [String] = []

        let event = Causality.Bus(name: "\(#function)")
        class MyState<Value: Causality.StateValue>: Causality.DynamicState<Value> {
            let stateId: Int
            var foo: String = "blah"

            init(stateId: Int) {
                self.stateId = stateId
            }
            enum CodingKeys: CodingKey {
                case stateId
            }
            override func encode(to encoder: Encoder) throws {
                try super.encode(to: encoder)
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.stateId, forKey: .stateId)
            }
        }

        // specifically testing that separate instances of identical types are treated identically
        let state1a = MyState<StringState>(stateId: 1)
        let state1b = MyState<StringState>(stateId: 1)
        let state2 = MyState<StringState>(stateId: 2)

        let g = DispatchGroup()
        g.enter()
        event.subscribe(state1a) { subscription, message in
            defer {
                g.leave()
            }

            print(message)
            resolvedStateValues.append(message.string)
        }

        g.enter()
        event.set(state: state1b, value: StringState(string: inputValues[1]!))
        g.enter()
        event.set(state: state2, value: StringState(string: inputValues[2]!))


        _ = g.wait(timeout: .now() + 1)
        XCTAssertEqual(expectedStateValues, resolvedStateValues, "Expeced state values: \(expectedStateValues)  Got instead: \(resolvedStateValues)")
    }

    func testThat_DynamicAddressingWithIdenticalParameters_IsTreatedIdentically_ForPushBeforeSubscribe() {
        let inputValues = [1:"a", 2:"b", 3: "c"]
        let expectedStateValues = ["a", "b"]
        var resolvedStateValues: [String] = []

        let event = Causality.Bus(name: "\(#function)")
        class MyState<Value: Causality.StateValue>: Causality.DynamicState<Value> {
            let stateId: Int
            var foo: String = "blah"

            init(stateId: Int) {
                self.stateId = stateId
            }
            enum CodingKeys: CodingKey {
                case stateId
            }
            override func encode(to encoder: Encoder) throws {
                try super.encode(to: encoder)
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.stateId, forKey: .stateId)
            }
        }

        // specifically testing that separate instances of identical types are treated identically
        let state1a = MyState<StringState>(stateId: 1)
        let state1b = MyState<StringState>(stateId: 1)
        let state2 = MyState<StringState>(stateId: 2)

        let g = DispatchGroup()
        
        g.enter()
        event.set(state: state1b, value: StringState(string: inputValues[1]!))

        g.enter()
        event.subscribe(state1a) { subscription, message in
            defer {
                g.leave()
            }

            print(message)
            resolvedStateValues.append(message.string)
        }

        g.enter()
        event.set(state: state1a, value: StringState(string: inputValues[1]!))
        event.set(state: state1b, value: StringState(string: inputValues[2]!))
        event.set(state: state2, value: StringState(string: inputValues[3]!))


        _ = g.wait(timeout: .now() + 1)
        XCTAssertEqual(expectedStateValues, resolvedStateValues, "Expeced state values: \(expectedStateValues)  Got instead: \(resolvedStateValues)")
    }

}
