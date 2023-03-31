import Parsing

/// Parses a request's fragment subcomponent with a substring parser.
public struct Fragment<ValueParser: Parser>: Parser where ValueParser.Input == Substring {

  @usableFromInline
  let valueParser: ValueParser

  /// Initializes a fragment parser that parses the fragment as a string in its entirety.
  @inlinable
  public init()
  where
    ValueParser == Parsers.MapConversion<
      Parsers.ReplaceError<Rest<Substring>>, Conversions.SubstringToString
    >
  {
    self.valueParser = Rest().replaceError(with: "").map(.string)
  }

  /// Initializes a fragment parser.
  ///
  /// - Parameter value: A parser that parses the fragment's substring value into something
  ///   more well-structured.
  @inlinable
  public init(@ParserBuilder<Substring> value: () -> ValueParser) {
    self.valueParser = value()
  }

  /// Initializes a fragment parser.
  ///
  /// - Parameter value: A conversion that transforms the fragment's substring value into
  ///   some other type.
  @inlinable
  public init<C>(_ value: C)
  where ValueParser == Parsers.MapConversion<Parsers.ReplaceError<Rest<Substring>>, C> {
    self.valueParser = Rest().replaceError(with: "").map(value)
  }

  @inlinable
  public func parse(_ input: inout URLRequestData) throws -> ValueParser.Output {
    guard var fragment = input.fragment?[...] else { throw RoutingError() }
    let output = try self.valueParser.parse(&fragment)
    input.fragment = String(fragment)
    return output
  }
}

extension Fragment: ParserPrinter where ValueParser: ParserPrinter {
  @inlinable
  public func print(_ output: ValueParser.Output, into input: inout URLRequestData) rethrows {
    input.fragment = String(try self.valueParser.print(output))
  }
}
