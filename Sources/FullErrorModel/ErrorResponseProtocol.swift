/// The Protocol for default error response.
public protocol ErrorResponseProtocol: Codable {
	/// The code of the reason.
	var code: String { get }

	/// The reason for the error.
	var reason: String { get }

	/// List with validation failures.
	var failures: [ValidationFailure]? { get }
}
