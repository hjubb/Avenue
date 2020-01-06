import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MainControllerTests.allTests),
        testCase(ChildControllerTests.allTests),
        testCase(SiblingControllerTests.allTests),
    ]
}
#endif
