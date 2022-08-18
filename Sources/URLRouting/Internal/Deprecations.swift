import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

// NB: Deprecated after 0.1.0:

extension URLRoutingClient {
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  @available(*, deprecated, renamed: "decodedResponse(for:as:decoder:)")
  public func request<Value: Decodable>(
    _ route: Route,
    as type: Value.Type = Value.self,
    decoder: JSONDecoder? = nil
  ) async throws -> (value: Value, response: URLResponse) {
    try await self.decodedResponse(for: route, as: type, decoder: decoder)
  }
}
