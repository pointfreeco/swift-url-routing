import Foundation
import Parsing
import Testing
import URLRouting

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct URLRoutingClientTests {
  #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    @Test
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func jsonDecoder_noDecoder() async throws {
      struct Response: Equatable, Decodable {
        let decodableValue: String
      }
      enum AppRoute {
        case test
      }
      let sut = URLRoutingClient<AppRoute>(request: { _ in
        (Data(#"{"decodableValue":"result"}"#.utf8), URLResponse())
      })
      let response = try await sut.decodedResponse(for: .test, as: Response.self)
      #expect(response.value == Response(decodableValue: "result"))
    }
    @Test
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func jsonDecoder_customDecoder() async throws {
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
          (Data(#"{"decodable_value":"result"}"#.utf8), URLResponse())
        }, decoder: customDecoder)
      let response = try await sut.decodedResponse(for: .test, as: Response.self)
      #expect(response.value == Response(decodableValue: "result"))
    }
    @Test
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func jsonDecoder_customDecoderForRequest() async throws {
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
          (Data(#"{"decodableValue":"result"}"#.utf8), URLResponse())
        }, decoder: customDecoder)
      let response = try await sut.decodedResponse(
        for: .test, as: Response.self, decoder: JSONDecoder())
      #expect(response.value == Response(decodableValue: "result"))
    }
  #endif
}
