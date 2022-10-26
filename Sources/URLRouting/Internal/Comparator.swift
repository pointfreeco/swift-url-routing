import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@usableFromInline
typealias Comparator<A> = (A, A) -> Bool

extension URLQueryItem {
  @inlinable
  static func comparator() -> Comparator<URLRequestData.Fields.Element> {
    { $0.key.compare($1.key, options: .numeric) == .orderedAscending }
  }
}
