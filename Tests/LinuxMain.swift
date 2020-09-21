import XCTest

import CausalityTests

var tests = [XCTestCaseEntry]()
tests += CausalityTests.allTests()
XCTMain(tests)
