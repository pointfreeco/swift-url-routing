// swift-tools-version: 5.5

import PackageDescription

let package = Package(
  name: "swift-url-routing",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(name: "URLRouting", targets: ["URLRouting"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.5.0"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.11.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.3.0"),
    .package(name: "Benchmark", url: "https://github.com/google/swift-benchmark", from: "0.1.1"),
  ],
  targets: [
    .target(
      name: "URLRouting",
      dependencies: [
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(name: "Parsing", package: "swift-parsing"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
      ]
    ),
    .testTarget(
      name: "URLRoutingTests",
      dependencies: [
        "URLRouting"
      ]
    ),
    .executableTarget(
      name: "swift-url-routing-benchmark",
      dependencies: [
        "URLRouting",
        .product(name: "Benchmark", package: "Benchmark"),
      ]
    ),
    .executableTarget(
      name: "variadics-generator",
      dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]
    ),
  ]
)

#if swift(>=5.6)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
