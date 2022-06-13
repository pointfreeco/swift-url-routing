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
///
/// > Note: Do not use the `Scheme` parser for the purpose of preferring to print a particular
/// > scheme from your router. Instead, consider using ``BaseURLPrinter`` via the `baseURL` and
/// > `baseRequestData` methods on routers.
public struct Scheme: ParserPrinter {
  @usableFromInline
  let name: String

  /// A parser of the `http` scheme.
  public static let http = Self("http")

  /// A parser of the `https` scheme.
  public static let https = Self("https")

  /// Initializes a scheme parser with a scheme name.
  ///
  /// - Parameter name: A scheme name.
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
