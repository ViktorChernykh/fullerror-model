
public struct VerificationsError: Error {
    // MARK: Stored properties
    public var failures: [ValidationFailure]
    
    // MARK: - Init
    public init(failures: [ValidationFailure]) {
        self.failures = failures
    }
}
