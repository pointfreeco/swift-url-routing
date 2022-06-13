import Parsing
import URLRouting
import XCTest

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

class URLRoutingTests: XCTestCase {
  func testMethod() {
    XCTAssertNoThrow(try Method.post.parse(URLRequestData(method: "POST")))
    XCTAssertEqual(try Method.post.print(), URLRequestData(method: "POST"))
  }

  func testHost() {
    XCTAssertNoThrow(try Host.custom("foo").parse(URLRequestData(host: "foo")))
    XCTAssertEqual(try Host.custom("foo").print(), URLRequestData(host: "foo"))
  }

  func testScheme() {
    XCTAssertNoThrow(try Scheme.http.parse(URLRequestData(scheme: "http")))
    XCTAssertEqual(try Scheme.http.print(), URLRequestData(scheme: "http"))
  }

  func testPath() {
    XCTAssertEqual(123, try Path { Int.parser() }.parse(URLRequestData(path: "/123")))
    XCTAssertThrowsError(try Path { Int.parser() }.parse(URLRequestData(path: "/123-foo"))) {
      error in
      XCTAssertEqual(
        """
        error: unexpected input
         --> input:1:5
        1 | /123-foo
          |     ^ expected end of input
        """,
        "\(error)"
      )
    }
  }

  func testFormData() throws {
    let p = Body {
      FormData {
        Field("name", .string)
        Field("age") { Int.parser() }
      }
    }

    var request = URLRequestData(body: .init("name=Blob&age=42&debug=1".utf8))
    let (name, age) = try p.parse(&request)
    XCTAssertEqual("Blob", name)
    XCTAssertEqual(42, age)
    XCTAssertEqual("debug=1", request.body.map { String(decoding: $0, as: UTF8.self) })
  }

  func testHeaders() throws {
    let p = Headers {
      Field("X-Haha", .string)
    }

    var req = URLRequest(url: URL(string: "/")!)
    req.addValue("Hello", forHTTPHeaderField: "X-Haha")
    req.addValue("Blob", forHTTPHeaderField: "X-Haha")
    var request = URLRequestData(request: req)!

    let name = try p.parse(&request)
    XCTAssertEqual("Hello", name)
    XCTAssertEqual(["x-haha": ["Blob"]], request.headers)
  }

  func testQuery() throws {
    let p = Query {
      Field("name")
      Field("age") { Int.parser() }
    }

    var request = URLRequestData(string: "/?name=Blob&age=42&debug=1")!
    let (name, age) = try p.parse(&request)
    XCTAssertEqual("Blob", name)
    XCTAssertEqual(42, age)
    XCTAssertEqual(["debug": ["1"]], request.query)
  }

  func testQueryDefault() throws {
    let p = Query {
      Field("page", default: 1) {
        Int.parser()
      }
    }

    var request = URLRequestData(string: "/")!
    let page = try p.parse(&request)
    XCTAssertEqual(1, page)
    XCTAssertEqual([:], request.query)

    XCTAssertEqual(
      try p.print(10),
      URLRequestData(query: ["page": ["10"]])
    )
    XCTAssertEqual(
      try p.print(1),
      URLRequestData(query: [:])
    )
  }

  func testFragment() throws {
    // test default initializer
    let q1 = Fragment()

    var request = try XCTUnwrap(URLRequestData(string: "#fragment"))
    XCTAssertEqual(
      "fragment",
      try q1.parse(&request)
    )
    XCTAssertEqual(
      URLRequestData(fragment: "fragment"),
      try q1.print("fragment")
    )

    struct Timestamp: Equatable, RawRepresentable {
      let rawValue: String
    }

    // test conversion initializer
    let q2 = Fragment(.string.representing(Timestamp.self))
    request = try XCTUnwrap(
      URLRequestData(string: "https://www.pointfree.co/episodes/ep182-invertible-parsing-map#t802"))
    XCTAssertEqual(
      Timestamp(rawValue: "t802"),
      try q2.parse(&request)
    )
    XCTAssertEqual(
      URLRequestData(fragment: "t802"),
      try q2.print(Timestamp(rawValue: "t802"))
    )

    // test parser builder initializer
    let p3 = Fragment {
      "section1"
    }

    request = try XCTUnwrap(URLRequestData(string: "#section1"))
    XCTAssertNoThrow(try p3.parse(&request))
    request = try XCTUnwrap(URLRequestData(string: "#section2"))
    XCTAssertThrowsError(try p3.parse(&request))
    XCTAssertEqual(
      .init(fragment: "section1"),
      try p3.print()
    )

    enum AppRoute: Equatable {
      case privacyPolicy(section: String)
    }

    // routing example
    let r = Route(.case(AppRoute.privacyPolicy(section:))) {
      Path {
        "legal"
        "privacy"
      }
      Fragment()
    }

    request = try XCTUnwrap(URLRequestData(string: "/legal/privacy#faq"))
    XCTAssertEqual(
      .privacyPolicy(section: "faq"),
      try r.parse(&request)
    )
    XCTAssertEqual(
      .init(path: "/legal/privacy", fragment: "faq"),
      try r.print(.privacyPolicy(section: "faq"))
    )
  }

  func testCookies() throws {
    struct Session: Equatable {
      var userId: Int
      var isAdmin: Bool
    }

    let p = Cookies /*(.destructure(Session.init(userId:isAdmin:)))*/ {
      Field("userId") { Int.parser() }
      Field("isAdmin") { Bool.parser() }
    }
    .map(.memberwise(Session.init(userId:isAdmin:)))

    var request = URLRequestData(headers: ["cookie": ["userId=42; isAdmin=true"]])
    XCTAssertEqual(
      Session(userId: 42, isAdmin: true),
      try p.parse(&request)
    )
    XCTAssertEqual(
      URLRequestData(headers: ["cookie": ["isAdmin=true; userId=42"]]),
      try p.print(Session(userId: 42, isAdmin: true))
    )
  }

  func testJSONCookies() {
    struct Session: Codable, Equatable {
      var userId: Int
    }

    let p = Cookies {
      Field("pf_session", .utf8.data.json(Session.self))
    }

    var request = URLRequestData(headers: ["cookie": [#"pf_session={"userId":42}; foo=bar"#]])
    XCTAssertEqual(
      Session(userId: 42),
      try p.parse(&request)
    )
    XCTAssertEqual(
      URLRequestData(headers: ["cookie": [#"pf_session={"userId":42}"#]]),
      try p.print(Session(userId: 42))
    )
  }

  func testBaseURL() throws {
    enum AppRoute { case home, episodes }

    let router = OneOf {
      Route(AppRoute.home)
      Route(AppRoute.episodes) {
        Path { "episodes" }
      }
    }

    XCTAssertEqual(
      "https://api.pointfree.co/v1/episodes?token=deadbeef",
      URLRequest(
        data:
          try router
          .baseURL("https://api.pointfree.co/v1?token=deadbeef")
          .print(.episodes)
      )?.url?.absoluteString
    )

    XCTAssertEqual(
      "http://localhost:8080/v1/episodes?token=deadbeef",
      URLRequest(
        data:
          try router
          .baseURL("http://localhost:8080/v1?token=deadbeef")
          .print(.episodes)
      )?.url?.absoluteString
    )
  }
}
