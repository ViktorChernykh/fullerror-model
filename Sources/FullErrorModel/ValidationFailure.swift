/// A structure for an array of validation errors.
public struct ValidationFailure: Codable, Sendable {
	// MARK: Stored properties
	/// Field name.
	public let field: String

	/// The code of the reason.
	public let code: String

	/// The reason for the error.
	public let reason: String

	/// Typed values for translating this failure.
	public let parameters: [String: ErrorParameterValueType]?

	// MARK: - Init
	public init(
		field: String,
		code: String,
		reason: String,
		parameters: [String: ErrorParameterValueType]? = nil
	) {
		self.field = field
		self.code = code
		self.reason = reason
		self.parameters = parameters
	}
}
