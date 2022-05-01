# swift-url-routing

A bidirectional router with more type safety and less fuss. This library is built with [Parsing][swift-parsing].

---

* [Motivation](#Motivation)
* [Getting started](#Getting-started)
* [Documentation](#Documentation)
* [License](#License)

## Learn More

This library was discussed in an [episode](http://pointfree.co/episodes/ep187-tour-of-parser-printers-url-routing) of [Point-Free](http://pointfree.co), a video series exploring functional programming and the Swift programming and the Swift language, hosted by [Brandon Williams](https://twitter.com/mbrandonw) and [Stephen Celis](https://twitter.com/stephencelis).

<a href="http://pointfree.co/episodes/ep187-tour-of-parser-printers-url-routing">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0187.jpeg" width="600">
</a>

## Motivation

URL routing is a ubiquitous problem in both client-side and server-side applications:

* Clients, such as iOS applications, need to route URLs for deep-linking, which amounts to picking apart a URL in order to figure out where to navigate the user in the app.
* Servers, such as [Vapor][vapor] applications, also need to pick apart URL requests to figure out what page to serve, but also need to _generate_ valid URLs for linking within the website.

This library provides URL routing function for both client and server applications, and does so in a composable, type-safe manner.

## Getting Started

To use the library you first begin with a domain modeling exercise. You model a route enum that represents each URL you want to recognize in your application, and each case of the enum holds the data you want to extract from the URL.

For example, if we had screens in our application that represent showing all books, showing a particular book, and searching books, we can model this as an enum:

```swift
enum AppRoute {
  case books
  case book(id: Int)
  case searchBooks(query: String, count: Int = 10)
}
```

Notice that we only encode the data we want to extract from the URL in these cases. There are no details of where this data lives in the URL, such as whether it comes from path parameters, query parameters or POST body data.

Those details are determined by the router, which can be constructed with the tools shipped in this library. Its purpose is to transform an incoming URL into the `AppRoute` type. For example:

```swift
import URLRouting

let appRouter = OneOf {
  // GET /books
  Route(.case(AppRoute.books))) {
    Path { "books" }
  }

  // GET /books/:id
  Route(.case(AppRoute.books(id:))) {
    Path { "books"; Digits() }
  }

  // GET /books/search?query=:query&count=:count
  Route(.case(AppRoute.searchBooks(query:count:))) {
    Path { "books"; "search" }
    Query {
      Field("query")
      Field("count", default: 10) { Digits() }
    }
  }
}
```

This router describes at a high-level how to pick apart the path components, query parameters, and more from a URL in order to transform it into a `AppRoute`.

Once this router is defined you can use it to implement deep-linking logic in your application. You can implement a single function that accepts a `URL`, use the router's `match` method to transform it into an `AppRoute`, and then switch on the route to handle each deep link destination:

```swift
func handleDeepLink(url: URL) throws {
  switch try appRouter.match(url: url) {
  case .books:
    // navigate to books screen

  case let .book(id: id):
    // navigate to book with id

  case let .searchBooks(query: query, count: count):
    // navigate to search screen with query and count
  }
}
```

This kind of routing is incredibly useful in client side iOS applications, but it can also be used in server-side applications. Even better, it can automatically transform `AppRoute` values back into URL's which is handy for linking to various parts of your website:

```swift
appRoute.path(for: .searchBooks(query: "Blob Bio"))
// /books/search?query=Blob%20Bio
```

```swift
Node.ul(
  books.map { book in
    .li(
      .a(
        .href(appRoute.path(for: .book(id: book.id))),
        book.title
      )
    )
  }
)
```
```html
<ul>
  <li><a href="/books/1">Blob Autobiography</a></li>
  <li><a href="/books/2">Blobbed around the world</a></li>
  <li><a href="/books/3">Blob's guide to success</a></li>
</ul>
```

## Documentation

The documentation for releases and main are available here:

* [main][swift-url-routing-docs]
* [0.1.0](https://pointfreeco.github.io/swift-url-routing/0.1.0/documentation/urlrouting)

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-url-routing-docs]: https://pointfreeco.github.io/swift-url-routing
[swift-parsing]: http://github.com/pointfreeco/swift-parsing
[vapor]: http://vapor.codes
