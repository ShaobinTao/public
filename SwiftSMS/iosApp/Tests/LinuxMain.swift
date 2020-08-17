import XCTest

import iosAppTests

var tests = [XCTestCaseEntry]()
tests += iosAppTests.allTests()
XCTMain(tests)
