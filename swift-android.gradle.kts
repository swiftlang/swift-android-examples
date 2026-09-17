//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift.org project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift.org project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// File: swift-android.gradle.kts
// Swift build script for Android projects using swiftly

import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.Exec
import org.gradle.api.file.DuplicatesStrategy

// Configuration class for Swift builds
data class SwiftConfig(
    var apiLevel: Int = 28, // Default API level
    var debugAbiFilters: Set<String> = setOf("arm64-v8a"),
    var debugExtraBuildFlags: List<String> = emptyList(),
    var releaseAbiFilters: Set<String> = setOf("arm64-v8a", "armeabi-v7a", "x86_64"),
    var releaseExtraBuildFlags: List<String> = emptyList(),
    var swiftlyPath: String? = null, // Optional custom swiftly path
    var swiftSDKPath: String? = null, // Optional custom Swift SDK path
    // Swift toolchain version passed to swiftly (e.g. "6.3", "main-snapshot").
    // Can be overridden via the SWIFT_VERSION environment variable, which is
    // useful for CI matrices that test multiple toolchains.
    var swiftVersion: String = System.getenv("SWIFT_VERSION")?.takeIf { it.isNotEmpty() } ?: "6.3",
    // Android Swift SDK artifactbundle suffix. Substituted into the bundle
    // directory name as "swift-${androidSdkVersion}.artifactbundle". Installed
    // bundle names vary across toolchains (release patch versions, snapshots,
    // etc.), so leaving this null (the default) auto-detects the installed
    // bundle instead of guessing a naming scheme. Set it explicitly, or via
    // the SWIFT_ANDROID_SDK_VERSION environment variable, to pin an exact bundle.
    var androidSdkVersion: String? = System.getenv("SWIFT_ANDROID_SDK_VERSION")?.takeIf { it.isNotEmpty() }
)

// Architecture definitions
data class Arch(
    val androidAbi: String,
    val triple: String,
    val swiftArch: String,
    val swiftTarget: String,
    val variantName: String
)

val architectures = mapOf(
    "arm64" to Arch(
        androidAbi = "arm64-v8a",
        triple = "aarch64-linux-android",
        swiftArch = "aarch64",
        swiftTarget = "aarch64-unknown-linux-android",
        variantName = "Arm64"
    ),
    "armv7" to Arch(
        androidAbi = "armeabi-v7a",
        triple = "arm-linux-androideabi",
        swiftArch = "armv7",
        swiftTarget = "armv7-unknown-linux-android",
        variantName = "Armv7"
    ),
    "x86_64" to Arch(
        androidAbi = "x86_64",
        triple = "x86_64-linux-android",
        swiftArch = "x86_64",
        swiftTarget = "x86_64-unknown-linux-android",
        variantName = "X86_64"
    ),
)

// Create or get existing Swift configuration
val swiftConfig = (project.extensions.findByName("swiftConfig") as? SwiftConfig)
    ?: SwiftConfig().also {
        project.extensions.add("swiftConfig", it)
    }

// Helper function to get swiftly executable path
fun getSwiftlyPath(): String {
    // First check if custom path is provided
    swiftConfig.swiftlyPath?.let {
        return it
    }

    // Try to find swiftly in common locations
    val homeDir = System.getProperty("user.home")
    val possiblePaths = listOf(
        "$homeDir/.swiftly/bin/swiftly",
        "$homeDir/.local/share/swiftly/bin/swiftly",
        "$homeDir/.local/bin/swiftly",
        "/usr/local/bin/swiftly",
        "/opt/homebrew/bin/swiftly",
        "/root/.local/share/swiftly/bin/swiftly"
    )

    for (path in possiblePaths) {
        if (file(path).exists()) {
            return path
        }
    }

    throw GradleException("Switly path not found. Please set swiftConfig.swiftlyPath or install the swiftly.")
}

fun getSwiftSDKPath(): String {
    // First check if custom path is provided
    swiftConfig.swiftSDKPath?.let {
        return it
    }

    // Try to find Swift SDK in common locations
    val homeDir = System.getProperty("user.home")
    val possiblePaths = listOf(
        "$homeDir/Library/org.swift.swiftpm/swift-sdks/",
        "$homeDir/.config/swiftpm/swift-sdks/",
        "$homeDir/.swiftpm/swift-sdks/",
        "/root/.swiftpm/swift-sdks/"
    )

    for (path in possiblePaths) {
        if (file(path).exists()) {
            return path
        }
    }

    throw GradleException("Swift SDK path not found. Please set swiftConfig.swiftSDKPath or install the Swift SDK for Android.")
}

// Resolve the installed Android Swift SDK artifactbundle suffix.
//
// Bundle directory names vary across toolchains and platforms (e.g. a
// release requested as "6.3" is installed by `swift sdk install` as
// "swift-6.3.3-RELEASE_android.artifactbundle"; snapshots use date-stamped
// tags entirely), so rather than guessing a naming scheme, scan the Swift
// SDK directory for what's actually installed:
//   - an explicit override (swiftConfig.androidSdkVersion or the
//     SWIFT_ANDROID_SDK_VERSION env var) always wins;
//   - with exactly one "*android*.artifactbundle" present, use it, whatever
//     it's named -- this covers the common case of a single SDK installed;
//   - with several present, prefer one whose name starts with the
//     configured swiftVersion, else fall back to the most recently
//     installed one;
//   - with none present, fall back to the historical guessed name so the
//     existing "resources directory not found" diagnostic still fires.
fun resolveAndroidSdkVersion(): String {
    swiftConfig.androidSdkVersion?.let { return it }

    val fallback = "${swiftConfig.swiftVersion}-RELEASE_android"
    val bundles = file(getSwiftSDKPath()).listFiles { candidate ->
        candidate.isDirectory && candidate.name.contains("android") && candidate.name.endsWith(".artifactbundle")
    }?.toList() ?: emptyList()

    val resolved = when (bundles.size) {
        0 -> null
        1 -> bundles.first()
        else -> bundles.firstOrNull { it.name.startsWith("swift-${swiftConfig.swiftVersion}") }
            ?: bundles.maxByOrNull { it.lastModified() }
    }

    return resolved?.name?.removePrefix("swift-")?.removeSuffix(".artifactbundle") ?: fallback
}

// Helper function to get Swift resources path
fun getSwiftResourcesPath(arch: Arch): String {
    val sdkVersion = resolveAndroidSdkVersion()
    return "${getSwiftSDKPath()}/swift-${sdkVersion}.artifactbundle/swift-android/swift-resources/usr/lib/swift_static-${arch.swiftArch}/"
}

// Function to create Swift build task
fun createSwiftBuildTask(
    buildTypeName: String,
    arch: Arch,
    isDebug: Boolean
): TaskProvider<Exec> {
    val taskName = "swiftBuild${arch.variantName}${buildTypeName.replaceFirstChar { it.uppercaseChar() }}"

    return tasks.findByName(taskName)?.let {
        tasks.named<Exec>(taskName)
    } ?: tasks.register<Exec>(taskName) {
        val swiftlyPath = getSwiftlyPath()
        val resourcesPath = getSwiftResourcesPath(arch)
        val swiftVersion = swiftConfig.swiftVersion

        // Build the SDK name based on architecture
        val sdkName = "${arch.swiftTarget}${swiftConfig.apiLevel}"
        val defaultArgs = listOf(
            "run", "+${swiftVersion}", "swift", "build",
            "--swift-sdk", sdkName,
            "--build-system", "native", // old build system until we can sort out the output paths
            "-Xswiftc", "-static-stdlib",
            "-Xswiftc", "-resource-dir",
            "-Xswiftc", resourcesPath
        )
        val configurationArgs = listOf("-c", if (isDebug) "debug" else "release")
        val extraArgs = if (isDebug) swiftConfig.debugExtraBuildFlags else swiftConfig.releaseExtraBuildFlags
        val arguments = defaultArgs + configurationArgs + extraArgs

        workingDir("src/main/swift")
        executable(swiftlyPath)
        args(arguments)

        doFirst {
            // Check if swiftly exists
            if (!file(swiftlyPath).exists() && swiftlyPath != "swiftly") {
                throw GradleException(
                    "swiftly not found at: $swiftlyPath\n" +
                            "Please install swiftly or configure the path in swiftConfig.swiftlyPath"
                )
            }

            // Check if resources directory exists
            if (!file(resourcesPath).exists()) {
                println("Warning: Swift resources directory not found at: $resourcesPath")
                println("You may need to install the Swift SDK for Android")
            }

            println("Building Swift for ${arch.variantName} ${if (isDebug) "Debug" else "Release"}")
            println("Using swiftly: $swiftlyPath")
            println("Swift SDK: $sdkName")
        }
    }
}

// Function to create copy task for Swift libraries
fun createCopySwiftLibrariesTask(
    buildTypeName: String,
    arch: Arch,
    isDebug: Boolean,
    swiftBuildTask: TaskProvider<Exec>
): TaskProvider<Copy> {
    val taskName = "copySwift${arch.variantName}${buildTypeName.replaceFirstChar { it.uppercaseChar() }}"

    return tasks.findByName(taskName)?.let {
        tasks.named<Copy>(taskName)
    } ?: tasks.register<Copy>(taskName) {
        val swiftPmBuildPath = if (isDebug) {
            "src/main/swift/.build/${arch.swiftTarget}${swiftConfig.apiLevel}/debug"
        } else {
            "src/main/swift/.build/${arch.swiftTarget}${swiftConfig.apiLevel}/release"
        }

        dependsOn(swiftBuildTask)

        // Copy c++ shared runtime libraries
        from("${getSwiftSDKPath()}/swift-${resolveAndroidSdkVersion()}.artifactbundle/swift-android/ndk-sysroot/usr/lib/${arch.triple}") {
            include("libc++_shared.so")
        }

        // Copy built libraries
        from(fileTree(swiftPmBuildPath) {
            include("*.so", "*.so.*")
        })

        if (isDebug) {
            into("src/debug/jniLibs/${arch.androidAbi}")
        }
        else {
            into("src/release/jniLibs/${arch.androidAbi}")
        }

        filePermissions {
            unix("0644".toInt(8))
        }
        duplicatesStrategy = DuplicatesStrategy.INCLUDE
    }
}

// Function to handle each variant
fun handleVariant(variant: Any) {
    val variantClass = variant::class.java

    // Get build type and name using reflection
    val buildTypeMethod = variantClass.getMethod("getBuildType")
    val buildType = buildTypeMethod.invoke(variant)
    val buildTypeClass = buildType::class.java

    val isJniDebuggableMethod = buildTypeClass.getMethod("isJniDebuggable")
    val isDebug = isJniDebuggableMethod.invoke(buildType) as Boolean

    val getNameMethod = variantClass.getMethod("getName")
    val variantName = getNameMethod.invoke(variant) as String

    val getBuildTypeNameMethod = buildTypeClass.getMethod("getName")
    val buildTypeName = getBuildTypeNameMethod.invoke(buildType) as String

    // Get ABI filters
    val abiFilters = if (isDebug) {
        swiftConfig.debugAbiFilters
    } else {
        swiftConfig.releaseAbiFilters
    }.takeIf { it.isNotEmpty() } ?: try {
        val getNdkMethod = buildTypeClass.getMethod("getNdk")
        val ndk = getNdkMethod.invoke(buildType)
        val getAbiFiltersMethod = ndk::class.java.getMethod("getAbiFilters")
        @Suppress("UNCHECKED_CAST")
        getAbiFiltersMethod.invoke(ndk) as? Set<String> ?: emptySet()
    } catch (e: Exception) {
        emptySet()
    }

    // Create tasks for each architecture
    architectures.values.forEach { arch ->
        if (abiFilters.isEmpty() || abiFilters.contains(arch.androidAbi)) {
            val swiftBuildTask = createSwiftBuildTask(buildTypeName, arch, isDebug)
            val copyTask = createCopySwiftLibrariesTask(buildTypeName, arch, isDebug, swiftBuildTask)

            // Mount to Android build pipeline - try multiple possible task names
            val capitalizedVariantName = variantName.replaceFirstChar { it.uppercaseChar() }
            tasks.findByName("merge${capitalizedVariantName}JniLibFolders")?.let { task ->
                task.dependsOn(copyTask)
            }
        }
    }
}

// Apply configuration after project evaluation
project.afterEvaluate {
    val androidExtension = project.extensions.findByName("android")
    if (androidExtension != null) {
        // Try applicationVariants first (for apps)
        try {
            val applicationVariantsMethod = androidExtension::class.java.getMethod("getApplicationVariants")
            val variants = applicationVariantsMethod.invoke(androidExtension)
            val allMethod = variants::class.java.getMethod("all", groovy.lang.Closure::class.java)

            allMethod.invoke(variants, object : groovy.lang.Closure<Unit>(this) {
                fun doCall(variant: Any) {
                    handleVariant(variant)
                }
            })
        } catch (e: NoSuchMethodException) {
            // No applicationVariants found...
        }

        // Try libraryVariants (for libraries)
        try {
            val libraryVariantsMethod = androidExtension::class.java.getMethod("getLibraryVariants")
            val variants = libraryVariantsMethod.invoke(androidExtension)
            val allMethod = variants::class.java.getMethod("all", groovy.lang.Closure::class.java)

            allMethod.invoke(variants, object : groovy.lang.Closure<Unit>(this) {
                fun doCall(variant: Any) {
                    handleVariant(variant)
                }
            })
        } catch (e: NoSuchMethodException) {
            // No libraryVariants found..
        }
    } else {
        throw GradleException("Android extension not found. Make sure to apply this script after the Android plugin.")
    }
}
