public import Foundation
import OrderedCollections

#if canImport(FoundationNetworking)
  public import FoundationNetworking
#endif

extension URLRequestData {
  /// Initializes parseable request data from a `URLRequest`.
  ///
  /// Useful for converting a `URLRequest` from the Foundation framework into parseable
  /// ``URLRequestData``.
  ///
  /// ```swift
  /// guard let requestData = URLRequestData(request: urlRequest)
  /// else { return }
  ///
  /// let route = try router.parse(requestData)
  /// ```
  ///
  /// - Parameter request: A URL request.
  public init?(request: URLRequest) {
    guard
      let url = request.url,
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else { return nil }

    self.init(
      method: request.httpMethod,
      scheme: components.scheme,
      user: components.user,
      password: components.password,
      host: components.host,
      port: components.port,
      path: components.path,
      query: components.percentEncodedQueryItems?.reduce(into: [:]) { query, item in
        query[item.name.urlFormDecoded, default: []].append(item.value?.urlFormDecoded)
      } ?? [:],
      fragment: components.fragment,
      headers: .init(
        request.allHTTPHeaderFields?.map { key, value in
          (key, value.split(separator: ",", omittingEmptySubsequences: false).map { String($0) })
        } ?? [],
        uniquingKeysWith: { $1 }
      ),
      body: request.httpBody
    )
  }

  /// Initializes a parseable URL request from a `URL`.
  public init?(url: URL) {
    self.init(request: URLRequest(url: url))
  }

  /// Initializes a parseable URL request from a URL string.
  public init?(string: String) {
    guard let url = URL(string: string)
    else { return nil }
    self.init(url: url)
  }
}

extension URLComponents {
  /// Initializes `URLComponents` from parseable/printable request data.
  ///
  /// Useful for converting ``URLRequestData`` into a `URL`.
  ///
  /// ```swift
  /// let requestData = try router.print(route)
  /// guard let urlRequest = URLRequest(data: requestData)
  /// else { return }
  /// ```
  ///
  /// - Parameter data: URL request data.
  public init(data: URLRequestData) {
    self.init()
    self.scheme = data.scheme
    self.user = data.user
    self.password = data.password
    self.host = data.host
    self.port = data.port
    self.path = "/\(data.path.joined(separator: "/"))"
    if !data.query.isEmpty {
      self.percentEncodedQueryItems = data.query.urlFormEncodedQueryItems
    }
    self.fragment = data.fragment
  }
}

extension URLRequestData.Fields {
  @usableFromInline
  var urlFormEncodedQueryItems: [URLQueryItem] {
    self.flatMap { name, values in
      values.map { URLQueryItem(name: name.urlFormEncoded, value: $0.map(\.urlFormEncoded)) }
    }
  }
}

extension StringProtocol {
  @usableFromInline
  var urlFormDecoded: String {
    let spaced = self.replacingOccurrences(of: "+", with: " ")
    return spaced.removingPercentEncoding ?? spaced
  }

  @usableFromInline
  var urlFormEncoded: String {
    self.addingPercentEncoding(withAllowedCharacters: .urlQueryItemAllowed) ?? String(self)
  }
}

extension CharacterSet {
  @usableFromInline
  static let urlQueryItemAllowed = CharacterSet.urlQueryAllowed
    .subtracting(CharacterSet(charactersIn: "+&="))
}

extension URLRequest {
  /// Initializes a `URLRequest` from parseable/printable request data.
  ///
  /// Useful for converting ``URLRequestData`` back into a `URLRequest`.
  ///
  /// ```swift
  /// let requestData = try router.print(route)
  /// guard let urlRequest = URLRequest(data: requestData)
  /// else { return }
  /// ```
  ///
  /// - Parameter data: URL request data.
  public init?(data: URLRequestData) {
    guard let url = URLComponents(data: data).url else { return nil }
    self.init(url: url)
    self.httpMethod = data.method
    for (name, values) in data.headers {
      for value in values {
        if let value = value {
          self.addValue(String(value), forHTTPHeaderField: name)
        }
      }
    }
    self.httpBody = data.body.map { Data($0) }
  }
}
