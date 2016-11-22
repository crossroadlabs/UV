import XCTest

#if os(Linux)
public func allTests() -> [XCTestCaseEntry] {
	 return [
		testCase(LoopTests.allTests),
		testCase(StreamTests.allTests),
		testCase(UVTests.allTests)
	]
}
#endif