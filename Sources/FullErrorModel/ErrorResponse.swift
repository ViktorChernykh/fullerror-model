/// Structure for  default error response.
public struct ErrorResponse: Codable {
    // MARK: Stored properties
    /// The code of the reason.
    public let code: String

    /// The reason for the error.
    public let reason: String

    /// List with validation failures.
    public let failures: [ValidationFailure]?

    // MARK: - Init
    public init(
        code: String = "",
        reason: String = "",
        failures: [ValidationFailure]? = []
    ) {
        self.code = code
        self.reason = reason
        self.failures = failures
    }
}
