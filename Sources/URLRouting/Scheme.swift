/// Parses a request's scheme.
///
/// Used to require a particular scheme at a particular endpoint.
///
/// ```swift
/// Route(.case(SiteRoute.custom)) {
///   Scheme("custom")  // Only route custom:// requests
///   ...
/// }
/// ```
public struct Scheme: ParserPrinter {
  @usableFromInline
  let name: String

  /// A parser of the `http` scheme.
  public static let http = Self("http")

  /// A parser of the `https` scheme.
  public static let https = Self("https")

  /// A parser of custom schemes.
  public static func custom(_ scheme: String) -> Self {
    Self(scheme)
  }

  /// Initializes a scheme parser with a scheme name.
  ///
  /// - Parameter name: A method name.
  @inlinable
  public init(_ name: String) {
    self.name = name
  }

  @inlinable
  public func parse(_ input: inout URLRequestData) throws {
    guard let scheme = input.scheme else { throw RoutingError() }
    try self.name.parse(scheme)
    input.scheme = nil
  }

  @inlinable
  public func print(_ output: (), into input: inout URLRequestData) {
    input.scheme = self.name
  }
}
