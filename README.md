# Swift Android Examples

This repository contains example applications that demonstrate how to use the
[Swift SDK for Android](https://swift.org/install). Each example showcases different
integration patterns for Swift on Android.

## Getting Started

The **[hello-swift-java](hello-swift-java/)** example is the recommended
approach for integrating Swift into Android applications. This example
demonstrates how to build a Swift library that can be seamlessly called from
Kotlin/Java code using [swift-java](https://github.com/swiftlang/swift-java),
which automatically generates the necessary Java wrappers and JNI bindings for
you.

The example consists of two components:

- **hashing-lib**: A Swift package that uses `swift-crypto` to provide SHA256
  hashing functionality
- **hashing-app**: A Kotlin Android app using Jetpack Compose UI that calls the
  Swift library

When you press the "Hash" button in the app, it calls directly from Kotlin into
Swift code to compute a SHA256 hash—no manual JNI code required. The swift-java
tooling handles all the bridging automatically, making it easy to expose Swift
APIs to your Android application with type safety and minimal boilerplate.

This approach is ideal for production Android applications where you want to write
business logic, algorithms, or libraries in Swift, while maintaining a standard
Kotlin/Java frontend.

## Other Examples

For those who want to explore alternative integration patterns or understand
lower-level details of how Swift integrates with Android, there are a number of
more manual examples provided.

An example of a purely native Swift app, which calls no Java APIs:
- **[native-activity](native-activity/)** - complete native Android activity with
OpenGL ES rendering written entirely in Swift.

Examples using raw JNI, without generated bridging sources:
- **[hello-swift-raw-jni](hello-swift-raw-jni/)** - basic Swift integration that calls a Swift function.
- **[hello-swift-raw-jni-callback](hello-swift-raw-jni-callback/)** - demonstrates bidirectional communication with Swift timer callbacks updating Android UI.
- **[hello-swift-raw-jni-library](hello-swift-raw-jni-library/)** - shows how to package Swift code as a reusable Android library component.
