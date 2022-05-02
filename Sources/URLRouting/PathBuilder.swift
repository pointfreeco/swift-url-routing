/// A custom parameter attribute that constructs path component parsers from closures. The
/// constructed parser runs a number of parsers against each patch component, one after the other,
/// and accumulates their outputs.
///
/// The ``Path`` router acts as an entry point into `@PathBuilder` syntax, where you can list all of
/// the path component parsers you want to run. For example, to route to a particular user by their
/// integer identifier:
///
/// ```swift
/// try Path {
///   "users"
///   Digits()
/// }
/// .match(path: "/users/42") // 42
/// ```
@resultBuilder
public enum PathBuilder {
  @inlinable
  public static func buildBlock<P: Parser>(_ parser: P) -> Component<P> {
    .init(parser)
  }

  public struct Component<ComponentParser: Parser>: Parser
  where ComponentParser.Input == Substring {
    @usableFromInline
    let componentParser: ComponentParser

    @usableFromInline
    init(_ componentParser: ComponentParser) {
      self.componentParser = componentParser
    }

    public func parse(_ input: inout URLRequestData) throws -> ComponentParser.Output {
      guard input.path.count >= 1 else { throw RoutingError() }
      return try self.componentParser.parse(input.path.removeFirst())
    }
  }
}

extension PathBuilder.Component: ParserPrinter where ComponentParser: ParserPrinter {
  public func print(_ output: ComponentParser.Output, into input: inout URLRequestData) rethrows {
    try input.path.prepend(self.componentParser.print(output))
  }
}
