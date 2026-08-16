import Foundation
import OrderedCollections
import Parsing
import Testing
import URLRouting

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct URLRoutingTests {
  @Test
  func method() throws {
    #expect(throws: Never.self) {
      try Method.post.parse(URLRequestData(method: "POST"))
    }

    #expect(try Method.post.print() == URLRequestData(method: "POST"))
  }

  @Test
  func host() throws {
    #expect(throws: Never.self) {
      try Host.custom("foo").parse(URLRequestData(host: "foo"))
    }

    #expect(try Host.custom("foo").print() == URLRequestData(host: "foo"))
  }

  @Test
  func scheme() throws {
    #expect(throws: Never.self) {
      try Scheme.http.parse(URLRequestData(scheme: "http"))
    }

    #expect(try Scheme.http.print() == URLRequestData(scheme: "http"))
  }

  @Test
  func path() throws {
    #expect(try Path { Int.parser() }.parse(URLRequestData(path: "/123")) == 123)
    
    let error = try #require(throws: (any Error).self) {
      try Path { Int.parser() }.parse(URLRequestData(path: "/123-foo"))
    }
    
    #expect(
        """
        error: unexpected input
         --> input:1:5
        1 | /123-foo
          |     ^ expected end of input
        """ ==
        String(describing: error)
    )
  }

  @Test
  func formData() throws {
    let p = Body {
      FormData {
        Field("name", .string)
        Field("age") { Int.parser() }
      }
    }

    var request = URLRequestData(body: .init("name=Blob&age=42&debug=1".utf8))
    let (name, age) = try p.parse(&request)
    #expect("Blob" == name)
    #expect(42 == age)
    #expect("debug=1" == request.body.map { String(decoding: $0, as: UTF8.self) })
  }

  @Test
  func headers() throws {
    let p = Headers {
      Field("X-Haha", .string)
    }

    var req = URLRequest(url: URL(string: "/")!)
    req.addValue("Hello", forHTTPHeaderField: "X-Haha")
    req.addValue("Blob", forHTTPHeaderField: "X-Haha")
    var request = URLRequestData(request: req)!

    let name = try p.parse(&request)
    #expect("Hello" == name)
    #expect(["x-haha": ["Blob"]] == request.headers)
  }

  @Test
  func query() throws {
    let p = Query {
      Field("name")
      Field("age") { Int.parser() }
    }

    var request = URLRequestData(string: "/?name=Blob&age=42&debug=1")!
    let (name, age) = try p.parse(&request)
    #expect("Blob" == name)
    #expect(42 == age)
    #expect(["debug": ["1"]] == request.query)

    #expect(try p.print(("Blob", 42)) == URLRequestData(query: ["name": ["Blob"], "age": ["42"]]))
  }

  @Test
  func queryDefault() throws {
    let p = Query {
      Field("page", default: 1) {
        Int.parser()
      }
    }

    var request = URLRequestData(string: "/")!
    let page = try p.parse(&request)
    #expect(1 == page)
    #expect([:] == request.query)

    #expect(try p.print(10) == URLRequestData(query: ["page": ["10"]]))
    #expect(try p.print(1) == URLRequestData(query: [:]))
  }

  @Test
  func fragment() throws {
    // test default initializer
    let q1 = Fragment()

    var request = try #require(URLRequestData(string: "#fragment"))
    #expect(try q1.parse(&request) == "fragment")
    #expect(try q1.print("fragment") == URLRequestData(fragment: "fragment"))

    struct Timestamp: Equatable, RawRepresentable {
      let rawValue: String
    }

    // test conversion initializer
    let q2 = Fragment(.string.representing(Timestamp.self))
    request = try #require(
      URLRequestData(string: "https://www.pointfree.co/episodes/ep182-invertible-parsing-map#t802")
    )
    #expect(try q2.parse(&request) == Timestamp(rawValue: "t802"))
    #expect(try q2.print(Timestamp(rawValue: "t802")) == URLRequestData(fragment: "t802"))

    // test parser builder initializer
    let p3 = Fragment {
      "section1"
    }

    request = try #require(URLRequestData(string: "#section1"))
    #expect(throws: Never.self) { try p3.parse(&request) }
    request = try #require(URLRequestData(string: "#section2"))
    #expect(throws: (any Error).self) { try p3.parse(&request) }
    #expect(try p3.print() == URLRequestData(fragment: "section1"))

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

    request = try #require(URLRequestData(string: "/legal/privacy#faq"))
    #expect(try r.parse(&request) == AppRoute.privacyPolicy(section: "faq"))
    #expect(
      try r.print(.privacyPolicy(section: "faq")) ==
      URLRequestData(path: "/legal/privacy", fragment: "faq")
    )
  }

  @Test
  func cookies() throws {
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
    #expect(try p.parse(&request) == Session(userId: 42, isAdmin: true))
    #expect(
      try p.print(Session(userId: 42, isAdmin: true)) ==
      URLRequestData(headers: ["cookie": ["userId=42; isAdmin=true"]])
    )
  }

  @Test
  func jsonCookies() throws {
    struct Session: Codable, Equatable {
      var userId: Int
    }

    let p = Cookies {
      Field("pf_session", .utf8.data.json(Session.self))
    }

    var request = URLRequestData(headers: ["cookie": [#"pf_session={"userId":42}; foo=bar"#]])
    #expect(try p.parse(&request) == Session(userId: 42))
    #expect(
      try p.print(Session(userId: 42)) ==
      URLRequestData(headers: ["cookie": [#"pf_session={"userId":42}"#]])
    )
  }

  @Test
  func baseURL() throws {
    enum AppRoute { case home, episodes }

    let router = OneOf {
      Route(AppRoute.home)
      Route(AppRoute.episodes) {
        Path { "episodes" }
      }
    }

    #expect(
      "https://api.pointfree.co/v1/episodes?token=deadbeef" ==
      URLRequest(
        data:
          try router
          .baseURL("https://api.pointfree.co/v1?token=deadbeef")
          .print(.episodes)
      )?.url?.absoluteString
    )

    #expect(
      "http://localhost:8080/v1/episodes?token=deadbeef" ==
      URLRequest(
        data:
          try router
          .baseURL("http://localhost:8080/v1?token=deadbeef")
          .print(.episodes)
      )?.url?.absoluteString
    )
  }
}
