import Foundation
import SourceKittenFramework

public struct XCTNullifyStoredPropertiesRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = XCTClassConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "xct_nullify_stored_properties",
        name: "XCTestCase nullify all stored properties",
        description: "XCTestCase should nullify all stored properties in tearDown().",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            class TestCase: XCTestCase {
              var api: API!
              var data: String? = "data"

              override func setUp() {
                super.setUp()
                api = API()
                api.data = data
              }

              override func tearDown() {
                api = nil
                data = nil
                super.tearDown()
              }
            }
            """
        ],
        triggeringExamples: [
            """
            class TestCase: XCTestCase {
              var ↓api: API!
              var data: String? = "data"

              override func setUp() {
                super.setUp()
                api = API()
              }

              override func tearDown() {
                data = nil
                super.tearDown()
              }
            }
            """,
            """
            class TestCase: XCTestCase {
              var ↓api: API!
              var ↓data: String? = "data"

              override func setUp() {
                super.setUp()
                api = API()
              }
            }
            """,
            """
            class TestCase: XCTestCase {
              var ↓api: API!
              var data: String? = "data"
              let ↓config = Config()

              override func tearDown() {
                data = nil
                super.tearDown()
              }
            }
            """
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let testCases = file.structureDictionary.classes(overrides: configuration.testClasses)

        return testCases.flatMap { (testCase: SourceKittenDictionary) -> [StyleViolation] in
            let allProperties = testCase.allStoredProperties

            guard let tearDownRange = testCase.method("tearDown()").map(file.bodyRange) else {
                // tearDown() is missed
                return violations(in: file, forProperties: allProperties)
            }

            let propertiesViolated = allProperties.filter {
                guard let name = $0.name else { return false }
                return file.match(
                    pattern: "\\s+\(name)\\s*=\\s*nil",
                    excludingSyntaxKinds: SyntaxKind.commentAndStringKinds,
                    range: tearDownRange
                ).isEmpty
            }

            return violations(in: file, forProperties: propertiesViolated)
        }
    }

    private func violations(in file: SwiftLintFile,
                            forProperties properties: [SourceKittenDictionary]) -> [StyleViolation] {
        return properties.map {
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severityConfiguration.severity,
                location: .init(file: file, byteOffset: $0.nameOffset ?? 0)
            )
        }
    }
}

extension SwiftLintFile {
    func bodyRange(of dictionary: SourceKittenDictionary) -> NSRange? {
        guard
            let offset = dictionary.bodyOffset,
            let length = dictionary.bodyLength,
            let range = stringView.byteRangeToNSRange(start: offset, length: length)
        else {
            return nil
        }
        return range
    }
}
