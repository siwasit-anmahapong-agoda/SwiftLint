import Foundation
import SourceKittenFramework

public struct XCTResetSharedStateRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = XCTResetSharedStateConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "xct_reset_shared_state",
        name: "XCTestCase reset shared state",
        description: "XCTestCase should reset shared state in tearDown().",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            class TestCase: XCTestCase {
              override func setUp() {
                super.setUp()
                MySharedStateComponent.setUp()
              }

              override func tearDown() {
                MySharedStateComponent.tearDown()
                super.tearDown()
              }

              func testComponent() {
                MySharedStateComponent.setUp(with: Configuration())
              }
            }
            """,
            """
            class TestCase: XCTestCase {
              override func setUp() {
                super.setUp()
                ComponentMock().setUp()
              }
            }
            class ComponentMock: Component {
              func setUp() {
                MySharedStateComponent.setUp()
              }
            }
            """
        ],
        triggeringExamples: [
            """
            class TestCase: XCTestCase {
              override func setUp() {
                super.setUp()
                ↓MySharedStateComponent.setUp()
              }

              override func tearDown() {
                super.tearDown()
              }
            }
            """,
            """
            class TestCase: XCTestCase {
              override func setUp() {
                super.setUp()
                ↓MySharedStateComponent.setUp()
              }
            }
            """,
            """
            class TestCase: XCTestCase {
              func testComponent() {
                ↓MySharedStateComponent.setUp(with: Configuration())
              }
            }
            """
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let patterns = configuration.patterns
        let testCases = file.structureDictionary.classes(overrides: configuration.testClasses)

        return testCases.flatMap { (testCase: SourceKittenDictionary) -> [StyleViolation] in
            guard let testCaseRange = file.bodyRange(of: testCase) else { return [] }

            let tearDownMethod = testCase.method("tearDown()")
            let violatedRanges = patterns.flatMap { (pattern: XCTResetSharedStateConfiguration.Pattern) -> [NSRange] in
                let setUpMatches = file.match(
                    pattern: pattern.setUp,
                    excludingSyntaxKinds: SyntaxKind.commentAndStringKinds,
                    range: testCaseRange
                )

                guard !setUpMatches.isEmpty else { return [] }

                guard let tearDownMethodRange = tearDownMethod.map(file.bodyRange) else {
                    return setUpMatches
                }

                let tearDownMatches = file.match(
                    pattern: pattern.tearDown,
                    excludingSyntaxKinds: SyntaxKind.commentAndStringKinds,
                    range: tearDownMethodRange
                )

                if !tearDownMatches.isEmpty {
                    return []
                }
                return setUpMatches
            }
            return violatedRanges.map {
                StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severityConfiguration.severity,
                    location: .init(file: file, byteOffset: file.stringView.byteOffset(fromLocation: $0.location))
                )
            }
        }
    }
}
