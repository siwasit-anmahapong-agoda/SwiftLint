import SourceKittenFramework

public struct XCTMissingSuperSetUpTearDownRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = XCTClassConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "xct_missing_super_setup_teardown",
        name: "XCTestCase missing super.setUp() or super.tearDown()",
        description: "XCTestCase that overrides setUp() or tearDown() methods should call super.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            class TestCase: XCTestCase {
              override func setUp() {
                super.setUp()
              }
              override func tearDown() {
                super.tearDown()
              }
            }
            """,
            """
            class TestCase: XCTestCase {}
            """,
            """
            struct MyStruct {
              func setUp() {
                print("setUp")
              }
              func tearDown() {
                print("tearDown")
              }
            }
            """
        ],
        triggeringExamples: [
            """
            class TestCase: XCTestCase {
            override func ↓setUp() {
              print("setUp")
            }
            override func ↓tearDown() {
              print("tearDown")
            }
            override class func ↓setUp() {
              print("setUp")
            }
            override class func ↓tearDown() {
              print("tearDown")
            }
            """
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let testCases = file.structureDictionary.classes(overrides: configuration.testClasses)

        return testCases.flatMap { (testCase: SourceKittenDictionary) -> [StyleViolation] in
            let methods = testCase.methods(
                names: ["setUp()", "tearDown()"],
                declarationKinds: [.functionMethodInstance, .functionMethodClass]
            )

            let methodsViolated = methods.compactMap { $0 }.filter {
                $0.superCallName.flatMap($0.call) == nil
            }

            return methodsViolated.map {
                StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severityConfiguration.severity,
                    location: .init(file: file, byteOffset: $0.nameOffset ?? 0)
                )
            }
        }
    }
}
