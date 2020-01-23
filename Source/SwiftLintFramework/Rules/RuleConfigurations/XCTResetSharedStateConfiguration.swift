public struct XCTResetSharedStateConfiguration: RuleConfiguration, Equatable {
    struct Pattern: Equatable {
        var setUp: String
        var tearDown: String

        init(setUp: String, tearDown: String) {
            self.setUp = setUp
            self.tearDown = tearDown
        }

        init(configuration: Any) throws {
            guard
                let pattern = configuration as? [String: String],
                let setUp = pattern["set_up"],
                let tearDown = pattern["tear_down"]
            else {
                throw ConfigurationError.unknownConfiguration
            }
            self.init(setUp: setUp, tearDown: tearDown)
        }
    }

    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var testClasses: [String] = ["XCTestCase"]
    private(set) var patterns: [Pattern] = [
        Pattern(setUp: "MySharedStateComponent\\s*\\.\\s*setUp", tearDown: "MySharedStateComponent\\s*\\.\\s*tearDown")
    ]

    public var consoleDescription: String {
        let patterns = self.patterns.map {
            "[set_up: \($0.setUp), tearDown: \($0.tearDown)]"
        }.joined(separator: ", ")
        return severityConfiguration.consoleDescription + ", test_classes: \(testClasses), patterns: \(patterns)"
    }

    public init() {}

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let testClasses = configuration["test_classes"] as? [String] {
            self.testClasses += testClasses
        }

        guard let patterns = configuration["patterns"] as? [[String: String]] else {
            throw ConfigurationError.unknownConfiguration
        }

        self.patterns = try patterns.map(Pattern.init(configuration:))
    }
}
