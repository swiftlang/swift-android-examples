// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AndroidNativeAppGlue",
  products: [
    .library(name: "AndroidNativeAppGlue", targets: ["AndroidNativeAppGlue"]),
    .library(name: "AndroidOpenGL", targets: ["AndroidOpenGL"]),
  ],
  targets: [
    .target(name: "AndroidNativeAppGlue"),
    // Header-only, so a system library rather than a C target
    .systemLibrary(name: "AndroidOpenGL"),
  ],
  cxxLanguageStandard: .cxx98
)
