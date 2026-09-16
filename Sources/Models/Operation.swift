public protocol Operation<Request, Result>: Sendable {
    associatedtype Request
    associatedtype Result
    associatedtype Failure: Error = any Error

    var run: @Sendable (Request) throws(Failure) -> Result { get }
}

extension Operation {
    public func callAsFunction(_ request: Request) throws(Failure) -> Result {
        try run(request)
    }
}

extension Operation where Request == Void {
    public func callAsFunction() throws(Failure) -> Result {
        try run(())
    }
}
