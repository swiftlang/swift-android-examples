// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

import class Foundation.FileManager
import class Foundation.ProcessInfo

func findJavaHome() -> String {
  if let home = ProcessInfo.processInfo.environment["JAVA_HOME"] {
    return home
  }

  let path = "\(FileManager.default.homeDirectoryForCurrentUser.path()).java_home"
  if let home = try? String(contentsOfFile: path, encoding: .utf8) {
    if let lastChar = home.last, lastChar.isNewline {
      return String(home.dropLast())
    }

    return home
  }

  fatalError("Please set the JAVA_HOME environment variable to point to where Java is installed.")
}
let javaHome = findJavaHome()

let javaIncludePath = "\(javaHome)/include"
#if os(Linux)
  let javaPlatformIncludePath = "\(javaIncludePath)/linux"
#elseif os(macOS)
  let javaPlatformIncludePath = "\(javaIncludePath)/darwin"
#else
  #error("Currently only macOS and Linux platforms are supported, this may change in the future.")
#endif

let package = Package(
  name: "HelloCppSwift",
  platforms: [.macOS(.v15)],
  products: [
    .library(
      name: "HelloCppSwift",
      type: .dynamic,
      targets: ["HelloCppSwift"])
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-java", branch: "main"),
  ],
  targets: [
    .binaryTarget(
      name: "HelloWorldCpp",
      path: "../cpp-lib/prebuilt/HelloWorldCpp.artifactbundle"
    ),
    .target(
      name: "HelloCppSwift",
      dependencies: [
        .target(name: "HelloWorldCpp"),
        .product(name: "SwiftJava", package: "swift-java"),
        .product(name: "CSwiftJavaJNI", package: "swift-java"),
        .product(name: "SwiftJavaRuntimeSupport", package: "swift-java"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v5),
        .unsafeFlags(["-I\(javaIncludePath)", "-I\(javaPlatformIncludePath)"], .when(platforms: [.macOS, .linux, .windows]))
      ],
      plugins: [
        .plugin(name: "JExtractSwiftPlugin", package: "swift-java")
      ]
    ),
  ]
)
