# Getting Started

Learn how to integrate URL Routing into your project and write your first router.

## Adding URL Routing as a dependency

To use the URL Routing library in a SwiftPM project, add it to the dependencies of your Package.swift and specify the `URLRouting` product in any targets that need access to the library:

```swift
let package = Package(
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.1.0"),
  ],
  targets: [
    .target(
      name: "<target-name>",
      dependencies: [.product(name: "URLRouting", package: "swift-url-routing")]
    )
  ]
)
```
