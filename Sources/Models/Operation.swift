public struct Operation<Request, Result>: Sendable {
    public var run: @Sendable (Request) throws -> Result

    public init(_ run: @escaping @Sendable (Request) throws -> Result) {
        self.run = run
    }

    public func callAsFunction(_ request: Request) throws -> Result {
        try run(request)
    }
}
