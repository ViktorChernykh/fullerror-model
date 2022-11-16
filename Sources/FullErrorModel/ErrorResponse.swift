/// Structure for  default error response.
public struct ErrorResponse: Codable {
    // MARK: Stored properties
    /// The code of the reason.
    public let code: String

    /// The reason for the error.
    public let reason: String

    /// The values for the error.
    public let values: [String]

    /// List with validation failures.
    public let failures: [ValidationFailure]?

    // MARK: - Init
    public init(
        code: String = "",
        reason: String = "",
        values: [String] = [],
        failures: [ValidationFailure]? = []
    ) {
        self.code = code
        self.reason = reason
        self.values = values
        self.failures = failures
    }
}
