import Parsing
import URLRouting
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

class URLRoutingClientTests: XCTestCase {
  #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func testJSONDecoder_noDecoder() async throws {
      struct Response: Equatable, Decodable {
        let decodableValue: String
      }
      enum AppRoute {
        case test
      }
      let sut = URLRoutingClient<AppRoute>(request: { _ in
        ("{\"decodableValue\":\"result\"}".data(using: .utf8)!, URLResponse())
      })
      let response = try await sut.responseData(for: .test, as: Response.self)
      XCTAssertEqual(response.value, .init(decodableValue: "result"))
    }
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func testJSONDecoder_customDecoder() async throws {
      struct Response: Equatable, Decodable {
        let decodableValue: String
      }
      enum AppRoute {
        case test
      }
      let customDecoder = JSONDecoder()
      customDecoder.keyDecodingStrategy = .convertFromSnakeCase
      let sut = URLRoutingClient<AppRoute>(
        request: { _ in
          ("{\"decodable_value\":\"result\"}".data(using: .utf8)!, URLResponse())
        }, decoder: customDecoder)
      let response = try await sut.responseData(for: .test, as: Response.self)
      XCTAssertEqual(response.value, .init(decodableValue: "result"))
    }
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func testJSONDecoder_customDecoderForRequest() async throws {
      struct Response: Equatable, Decodable {
        let decodableValue: String
      }
      enum AppRoute {
        case test
      }
      let customDecoder = JSONDecoder()
      customDecoder.keyDecodingStrategy = .convertFromSnakeCase
      let sut = URLRoutingClient<AppRoute>(
        request: { _ in
          ("{\"decodableValue\":\"result\"}".data(using: .utf8)!, URLResponse())
        }, decoder: customDecoder)
      let response = try await sut.responseData(for: .test, as: Response.self, decoder: .init())
      XCTAssertEqual(response.value, .init(decodableValue: "result"))
    }
  #endif
}
