// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "swift-url-routing",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v15),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "URLRouting", targets: ["URLRouting"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.5.0"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "2.1.0"),
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.15.0"),
    .package(url: "https://github.com/google/swift-benchmark", from: "0.1.1"),
  ],
  targets: [
    .target(
      name: "URLRouting",
      dependencies: [
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(name: "Parsing", package: "swift-parsing"),
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
        .product(name: "Benchmark", package: "swift-benchmark"),
      ]
    ),
    .executableTarget(
      name: "variadics-generator",
      dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]
    ),
  ],
  swiftLanguageModes: [.v5]
)

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(contentsOf: [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InferSendableFromCaptures"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
  ])
}
