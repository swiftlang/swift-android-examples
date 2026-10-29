// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "ShowcaseKit",
  platforms: [.macOS(.v15), .iOS(.v18)],
  products: [
    .library(
      name: "ShowcaseKit",
      type: .dynamic,
      targets: ["ShowcaseKit"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-java", from: "0.5.1")
  ],
  targets: [
    .target(
      name: "ShowcaseKit",
      dependencies: [
        .product(name: "SwiftJava", package: "swift-java")
      ],
      swiftSettings: [
        .swiftLanguageMode(.v5)
      ],
      plugins: [
        .plugin(name: "JExtractSwiftPlugin", package: "swift-java")
      ]
    ),
    .testTarget(
      name: "ShowcaseKitTests",
      dependencies: ["ShowcaseKit"]
    ),
  ]
)
