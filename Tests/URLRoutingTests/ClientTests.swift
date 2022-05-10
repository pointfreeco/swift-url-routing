import Parsing
import URLRouting
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class ClientTests: XCTestCase {
  enum TestRoute: Equatable {
    case one
    case child(ChildRoute)
  }

  enum ChildRoute: Equatable {
    case one
    case two
  }

  static let router = OneOf {
    Route(.case(TestRoute.one)) {
      Path { "one" }
    }
    Route(.case(TestRoute.child)) {
      Path { "child" }
      OneOf {
        Route(.case(ChildRoute.one)) {
          Path { "one" }
        }
        Route(.case(ChildRoute.two)) {
          Path { "two" }
        }
      }
    }
  }

  func testBasics() async throws {
    let client = URLRoutingClient<TestRoute>.failing
      .override(.one) { try .ok("result") }

    let (value, response) = try await client.request(.one, as: String.self)

    XCTAssertEqual("result", value)
    XCTAssertEqual(200, (response as! HTTPURLResponse).statusCode)
  }
}
