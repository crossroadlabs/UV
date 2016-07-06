import XCTest

@testable import UVTestSuite

XCTMain([
	testCase(LoopTests.allTests),
	testCase(StreamTests.allTests),
	testCase(UVTests.allTests),
])