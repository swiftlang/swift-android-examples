# C++ to Swift to Android Integration

This example demonstrates how to call C++ code from Android through Swift. The app uses a C++ library that provides basic calculator functions (add and multiply), wraps them in Swift, and calls them from an Android Kotlin app.

## Overview

The project is structured into three main parts:

1. **`cpp-lib`**: A C++ library with basic calculator functions (`add` and `multiply`). This is built using CMake and packaged as an artifactbundle for consumption by Swift.

2. **`swift-lib`**: A Swift package that wraps the C++ functions and exposes them to Android using [swift-java](https://github.com/swiftlang/swift-java). The Swift code calls the C++ functions and provides JNI bindings automatically.

3. **`app`**: A standard Android application written in Kotlin that calls the Swift-wrapped C++ functions and displays the results.

## Prerequisites

Before you can build and run this project, you need to have the following installed:

* **Java Development Kit (JDK)**: We recommend using JDK 25. Ensure the `JAVA_HOME` environment variable is set to your JDK installation path.
* **Swiftly**: You need to install [Swiftly](https://www.swift.org/swiftly/documentation/swiftly/getting-started/)
* **Swift SDK for Android**: You need to install the [Swift SDK for Android](https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html)
* **Android NDK**: Required to build the C++ library. Set the `ANDROID_NDK_HOME` environment variable to your NDK installation path.

## Setup and Configuration

### 1. Build the C++ Library

Before building the Android app, you need to build the C++ library:

```bash
cd hello-cpp-swift/cpp-lib
./build-android-static.sh
```

This will create the `prebuilt/HelloWorldCpp.artifactbundle` directory containing the compiled C++ static libraries for all Android architectures (arm64-v8a, armeabi-v7a, x86_64).

### 2. Publish `swift-java` packages locally

As the `swift-java` project does not yet publish the necessary Java packages needed at runtime, we need to do it ourselves.

> Note: This step will not be necessary once swift-java publishes releases.

First, ensure you have JDK 25 installed and configured:

```bash
# Install sdkman if you don't have it
curl -s "https://get.sdkman.io" | bash

# Restart terminal, then install JDK 25
sdk install java 25.0.1-amzn --use
export JAVA_HOME="${HOME}/.sdkman/candidates/java/current"
```

Then publish the swift-java packages:

```bash
cd hello-cpp-swift/swift-lib/src/main/swift
swift package resolve
./.build/checkouts/swift-java/gradlew --project-dir .build/checkouts/swift-java :SwiftKitCore:publishToMavenLocal
```

## Running the example

1. Open the `swift-android-examples` project in Android Studio.

2. Select the `hello-cpp-swift:app` Gradle target.

3. Run the app on an Android emulator or a physical device.

4. The app will display the results of C++ calculations (10 + 5 and 10 × 5) called through Swift.

## Building from command line

```bash
# From the project root directory
./gradlew :hello-cpp-swift:app:assembleDebug

# Install on device/emulator
./gradlew :hello-cpp-swift:app:installDebug
```

## How it works

1. **C++ Layer** (`cpp-lib/src/calculator.cpp`):
   ```cpp
   int add(int a, int b) {
       return a + b;
   }
   ```

2. **Swift Layer** (`swift-lib/Sources/HelloCppSwift/Calculator.swift`):
   ```swift
   import HelloWorldCpp

   public func addNumbers(_ a: Int32, _ b: Int32) -> Int32 {
       return add(a, b)
   }
   ```

3. **Android/Kotlin Layer** (`app/MainActivity.kt`):
   ```kotlin
   val sum = com.example.hellocppswift.HelloCppSwift.addNumbers(10, 5)
   ```

The Swift code is automatically wrapped with JNI bindings using the `swift-java` JExtract plugin, making it callable from Kotlin/Java code.

## Rebuilding the C++ Library

If you make changes to the C++ code, you need to rebuild the artifactbundle:

```bash
cd hello-cpp-swift/cpp-lib
./build-android-static.sh
```

Then rebuild the Android app to pick up the changes.
