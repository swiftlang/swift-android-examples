# Swift as Android Library

This example demonstrates how to package Swift code as a reusable Android library, without the use of swift-java interoperability support, just by using raw JNI. It shows how to create a Swift library that can be consumed by other Android applications, making Swift functionality available as a standard Android library component.

## Overview

The project consists of:

1. **Swift Library**: A `SwiftLibrary` class that declares external Swift functions and loads the native library.
2. **Swift Implementation**: Implements the library functions using JNI conventions for consumption by other Android projects.

## Prerequisites

Before you can build and run this project, you need to have the following installed:

* **Java Development Kit (JDK)**: We recommend using JDK 25. Ensure the `JAVA_HOME` environment variable is set to your JDK installation path.
* **Swiftly**: You need to install [Swiftly](https://www.swift.org/swiftly/documentation/swiftly/getting-started/)
* **Swift SDK for Android**: You need to install the [Swift SDK for Android](https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html)

## Building the library

1. Open the `swift-android-examples` project in Android Studio.

2. Select the `hello-swift-raw-jni-library` Gradle target.

3. Build the library (it doesn't have a runnable app).

## Building from command line

```bash
# Build the library
./gradlew :hello-swift-raw-jni-library:assembleDebug

# Build the AAR file
./gradlew :hello-swift-raw-jni-library:bundleReleaseAar
```

After a successful build, the Android library will be located at `hello-swift-raw-jni-library/build/outputs/aar/hello-swift-raw-jni-library-release.aar`.

## Using the library in other projects

1. Copy the generated AAR file to your project's `libs/` directory
2. Add the dependency in your `build.gradle`:
   ```gradle
   implementation files('libs/hello-swift-raw-jni-library-release.aar')
   ```
3. Use the `SwiftLibrary` class in your code
