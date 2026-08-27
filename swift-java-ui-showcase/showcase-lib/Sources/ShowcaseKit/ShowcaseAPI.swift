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

// The Swift <-> Java boundary of the showcase.
//
// These three functions are the only public symbols in the package, so they
// are all that JExtract exposes to Java (as static methods on the generated
// `com.example.showcasekit.ShowcaseKit` class). Everything crosses the
// boundary as a JSON string, in the schema documented in
// `swift-java-ui-showcase/README.md`:
//
//   Compose event -> showcaseDispatch(screen, component, event JSON)
//     -> Swift mutates state -> returns new screen JSON -> Compose re-renders
//
// Plain `(String...) -> String` top-level functions are used deliberately:
// they are the shape JExtract's JNI mode bridges most simply, and the JSON
// payload keeps richer Swift types (enums with payloads, optionals, arrays
// of structs) from ever needing to cross the boundary themselves.
//
// All three functions must be called from the Android main thread.

/// Returns the registry of showcase screens (ids and titles) as JSON.
/// The Kotlin navigation graph is built from this list.
public func showcaseScreens() -> String {
  ShowcaseStore.shared.screensJSON()
}

/// Returns the current component tree of one screen as JSON.
public func showcaseScreen(_ id: String) -> String {
  ShowcaseStore.shared.screenJSON(id)
}

/// Applies a user event to a component on a screen and returns the screen's
/// new component tree as JSON.
public func showcaseDispatch(_ screenId: String, _ componentId: String, _ eventJSON: String)
  -> String
{
  ShowcaseStore.shared.dispatch(
    screenId: screenId, componentId: componentId, eventJSON: eventJSON)
}
