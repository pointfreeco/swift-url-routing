/// Parses a request's host.
///
/// Used to require a particular host at a particular endpoint.
///
/// ```swift
/// Route(.case(SiteRoute.custom)) {
///   Host("custom")  // Only routes scheme://custom requests
///   ...
/// }
/// ```
///
/// > Note: Do not use the `Host` parser for the purpose of preferring to print a particular
/// > host from your router. Instead, consider using ``BaseURLPrinter`` via the `baseURL` and
/// > `baseRequestData` methods on routers.
public struct Host: ParserPrinter {
  @usableFromInline
  let name: String

  /// A parser of custom hosts.
  public static func custom(_ host: String) -> Self {
    Self(host)
  }

  /// Initializes a host parser with a host name.
  ///
  /// - Parameter name: A host name.
  @inlinable
  public init(_ name: String) {
    self.name = name
  }

  @inlinable
  public func parse(_ input: inout URLRequestData) throws {
    guard let host = input.host else { throw RoutingError() }
    try self.name.parse(host)
    input.host = nil
  }

  @inlinable
  public func print(_ output: (), into input: inout URLRequestData) {
    input.host = self.name
  }
}
