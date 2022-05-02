/// Parses a request's path components.
///
/// Useful for incrementally consuming path components from the beginning of a URL.
///
/// For example, you could route to a particular user based off a path to their integer identifier:
///
/// ```swift
/// try Path {
///   "users"
///   Digits()
/// }
/// .match(path: "/users/42")
/// // 42
/// ```
public struct Path<ComponentParsers: Parser>: Parser
where ComponentParsers.Input == URLRequestData {
  @usableFromInline
  let componentParsers: ComponentParsers

  @inlinable
  public init(@PathBuilder build: () -> ComponentParsers) {
    self.componentParsers = build()
  }

  @inlinable
  public func parse(_ input: inout URLRequestData) rethrows -> ComponentParsers.Output {
    try self.componentParsers.parse(&input)
  }
}

extension Path: ParserPrinter where ComponentParsers: ParserPrinter {
  @inlinable
  public func print(_ output: ComponentParsers.Output, into input: inout URLRequestData) rethrows {
    try self.componentParsers.print(output, into: &input)
  }
}
