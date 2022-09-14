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

  @inlinable
  public static func buildPartialBlock<P: Parser>(first: P) -> Component<P> {
    .init(first)
  }
  public static func buildPartialBlock<P0: ParserPrinter, P1: ParserPrinter>(
    accumulated p0: P0,
    next p1: Optionally<P1>
  ) -> AnyParserPrinter<URLRequestData, (P0.Output, P1.Output?)>
  where
    P0.Input == URLRequestData,
    P1.Input == Substring
  {
    .init(
      parse: { input in
        guard input.path.count >= 1
        else { throw RoutingError() }

        let o0 = try p0.parse(&input)
        if input.path.isEmpty {
          return (o0, nil)
        } else {
          let o1 = try Parse {
            p1
            End()
          }.parse(input.path[0])
          input.path.removeFirst()
          return (o0, o1)
        }
      },
      print: { output, input in
        if let secondComponent = output.1 {
          input.path.prepend(try p1.print(secondComponent))
        }
        try p0.print(output.0, into: &input)
      }
    )
  }

  public struct Component<ComponentParser: Parser>: Parser
  where ComponentParser.Input == Substring {
    @usableFromInline
    let componentParser: ComponentParser

    @usableFromInline
    init(_ componentParser: ComponentParser) {
      self.componentParser = componentParser
    }

    @inlinable
    public func parse(_ input: inout URLRequestData) throws -> ComponentParser.Output {
      guard input.path.count >= 1 else { throw RoutingError() }
      return try self.componentParser.parse(input.path.removeFirst())
    }
  }
}

extension PathBuilder.Component: ParserPrinter where ComponentParser: ParserPrinter {
  @inlinable
  public func print(_ output: ComponentParser.Output, into input: inout URLRequestData) rethrows {
    try input.path.prepend(self.componentParser.print(output))
  }
}
