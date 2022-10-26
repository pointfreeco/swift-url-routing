import Parsing
import URLRouting
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class URLRequestDataTests: XCTestCase {
  func testQuerySorting() throws {
    let components = URLComponents(
      data: URLRequestData(
        query: [
          "a10": ["value"],
          "a1": ["value"],
          "a2": ["value"],
          "b1": ["value"],
        ]
      )
    )
    
    XCTAssertEqual(
      ["a1", "a2", "a10", "b1"],
      try XCTUnwrap(components.queryItems).map(\.name)
    )
  }
}
