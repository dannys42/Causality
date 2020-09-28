//
//  StateTests.swift
//  
//
//  Created by Danny Sung on 09/28/2020.
//

import Foundation
import XCTest
@testable import Causality

fileprivate struct StringState: Causality.State {
    let string: String
}
fileprivate struct NumberState: Causality.State {
    let number: Int
}
fileprivate let InterestingString = Causality.StatefulEvent<StringState>(name: "Foo")
fileprivate let FunNumber = Causality.StatefulEvent<NumberState>(name: "Foo")

final class StateTests: XCTestCase {

    func testThat_InitialState_DoesNotExist() {
        let bus = Causality.Bus(name: "\(#function)")

        let hasState = bus.hasState(event: InterestingString)
        let state = bus.getState(event: InterestingString)

        XCTAssertFalse(hasState, "Expect hasState == false on initialization")
        XCTAssertNil(state, "Expect getState == nil on initialization ")
    }

    func testThat_StateExists_AfterPublish() {
        let inputValue = StringState(string: "Hello world!")
        let expectedValue = inputValue
        let resolvedValue: StringState?
        let bus = Causality.Bus(name: "\(#function)")

        bus.publish(event: InterestingString, state: inputValue)

        let hasState = bus.hasState(event: InterestingString)
        resolvedValue = bus.getState(event: InterestingString)

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

        bus.publish(event: InterestingString, state: inputValue)

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

        bus.publish(event: InterestingString, state: inputValue)

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

        bus.publish(event: InterestingString, state: stateValue)

        g.enter()
        _ = bus.subscribe(InterestingString) { state in
            defer { g.leave() }

            resolvedStateChangeCount += 1
        }

        bus.publish(event: InterestingString, state: stateValue)

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

        bus.publish(event: InterestingString, state: stateValue1)
        bus.publish(event: InterestingString, state: stateValue2)

        sleep(1)

        XCTAssertEqual(resolvedStateChangeCount, expectedStateChangeCount, "Expected count: \(expectedStateChangeCount).  Instead got: \(resolvedStateChangeCount)")
    }
}
