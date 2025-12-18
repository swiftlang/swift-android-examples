#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "Error: ANDROID_NDK_HOME environment variable is not set"
    echo "Please set it to your Android NDK installation path"
    exit 1
fi

if [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "Error: ANDROID_NDK_HOME points to non-existent directory: $ANDROID_NDK_HOME"
    exit 1
fi

ANDROID_TOOLCHAIN="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"

if [ ! -f "$ANDROID_TOOLCHAIN" ]; then
    echo "Error: Android toolchain file not found at: $ANDROID_TOOLCHAIN"
    exit 1
fi

ANDROID_API=28

ABIS=(
    "arm64-v8a:android-aarch64"
    "armeabi-v7a:android-armv7"
    "x86_64:android-x86_64"
)

echo "Building HelloWorldCpp static libraries for Android..."

for ABI_ENTRY in "${ABIS[@]}"; do
    ABI="${ABI_ENTRY%%:*}"
    echo "Building for $ABI..."

    BUILD_DIR="build/android-static/$ABI"
    mkdir -p "$BUILD_DIR"

    cmake -S . -B "$BUILD_DIR" \
        -DCMAKE_TOOLCHAIN_FILE="$ANDROID_TOOLCHAIN" \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM="android-$ANDROID_API" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=17

    cmake --build "$BUILD_DIR" --config Release

    echo "✓ Built $ABI"
done

echo ""
echo "Creating artifactbundle..."

ARTIFACTBUNDLE_DIR="prebuilt/HelloWorldCpp.artifactbundle"

for ABI_ENTRY in "${ABIS[@]}"; do
    ABI="${ABI_ENTRY%%:*}"
    BUNDLE_DIR="${ABI_ENTRY##*:}"

    mkdir -p "$ARTIFACTBUNDLE_DIR/$BUNDLE_DIR/Headers"

    cp "build/android-static/$ABI/libHelloWorldCpp.a" "$ARTIFACTBUNDLE_DIR/$BUNDLE_DIR/"

    cp include/calculator.h "$ARTIFACTBUNDLE_DIR/$BUNDLE_DIR/Headers/"
    cp include/module.modulemap "$ARTIFACTBUNDLE_DIR/$BUNDLE_DIR/Headers/"

    echo "✓ Created artifactbundle for $BUNDLE_DIR"
done

cat > "$ARTIFACTBUNDLE_DIR/info.json" << 'EOF'
{
  "schemaVersion": "1.0",
  "artifacts": {
    "HelloWorldCpp": {
      "version": "1.0.0",
      "type": "staticLibrary",
      "variants": [
        {
          "path": "android-aarch64/libHelloWorldCpp.a",
          "supportedTriples": ["aarch64-unknown-linux-android"],
          "staticLibraryMetadata": {
            "headerPaths": ["android-aarch64/Headers"],
            "moduleMapPath": "android-aarch64/Headers/module.modulemap"
          }
        },
        {
          "path": "android-armv7/libHelloWorldCpp.a",
          "supportedTriples": ["armv7-unknown-linux-android"],
          "staticLibraryMetadata": {
            "headerPaths": ["android-armv7/Headers"],
            "moduleMapPath": "android-armv7/Headers/module.modulemap"
          }
        },
        {
          "path": "android-x86_64/libHelloWorldCpp.a",
          "supportedTriples": ["x86_64-unknown-linux-android"],
          "staticLibraryMetadata": {
            "headerPaths": ["android-x86_64/Headers"],
            "moduleMapPath": "android-x86_64/Headers/module.modulemap"
          }
        }
      ]
    }
  }
}
EOF

echo "✓ Generated info.json"
echo ""
echo "All Android static libraries built successfully!"
echo "Artifactbundle created at: $ARTIFACTBUNDLE_DIR"
