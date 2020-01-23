public struct XCTClassConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var testClasses: [String] = ["XCTestCase"]

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", test_classes: \(testClasses)"
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
    }
}
