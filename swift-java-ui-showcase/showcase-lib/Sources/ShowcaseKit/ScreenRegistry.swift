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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

/// One screen of the showcase: an identity, a title, a reducer, and a
/// declarative body. Each conforming type is its own independent store —
/// it owns its screen's state directly, with no shared state between
/// screens. `ScreenRegistry` below only routes to the right one; it is not
/// itself a single global store.
///
/// To add a new screen, conform to this protocol and append an instance to
/// `ScreenRegistry.shared` — no Kotlin changes are needed; the navigation
/// graph is data-driven from this registry.
protocol ScreenDefinition: AnyObject {
  var id: String { get }
  var title: String { get }

  /// Applies an action to this screen's state. Named `reduce` to match
  /// ReSwift's vocabulary, but — unlike a ReSwift reducer — this mutates the
  /// conforming instance in place rather than returning new state; there is
  /// no single immutable app-state tree here, each screen owns its own
  /// mutable state directly.
  func reduce(_ action: Action, componentId: String)
  func body() -> [Component]
}

/// Wire structs matching the JSON contract in the README.
struct ScreenSummary: Codable, Equatable {
  let id: String
  let title: String
}

struct ScreenList: Codable, Equatable {
  let screens: [ScreenSummary]
}

struct Screen: Codable, Equatable {
  let id: String
  let title: String
  let components: [Component]
}

/// Routes to the per-screen store whose `id` matches. Holds no UI state of
/// its own — each `ScreenDefinition` instance in `screens` is the actual
/// store for its screen. All entry points are called from the Android main
/// thread — that invariant is what makes the unsynchronized singleton safe.
final class ScreenRegistry {
  static let shared = ScreenRegistry()

  private let screens: [any ScreenDefinition]

  init(screens: [any ScreenDefinition] = ScreenRegistry.defaultScreens()) {
    self.screens = screens
  }

  static func defaultScreens() -> [any ScreenDefinition] {
    [
      ButtonsScreen(),
      SelectionScreen(),
      SlidersScreen(),
      TextInputsScreen(),
      PickersScreen(),
      FormScreen(),
      FeedbackScreen(),
    ]
  }

  func screensJSON() -> String {
    encode(ScreenList(screens: screens.map { ScreenSummary(id: $0.id, title: $0.title) }))
  }

  func screenJSON(_ id: String) -> String {
    guard let screen = screens.first(where: { $0.id == id }) else {
      return encode(errorScreen("Unknown screen: \(id)"))
    }
    return encode(Screen(id: screen.id, title: screen.title, components: screen.body()))
  }

  func dispatch(screenId: String, componentId: String, actionJSON: String) -> String {
    guard let screen = screens.first(where: { $0.id == screenId }) else {
      return encode(errorScreen("Unknown screen: \(screenId)"))
    }
    do {
      let action = try JSONDecoder().decode(Action.self, from: Data(actionJSON.utf8))
      screen.reduce(action, componentId: componentId)
    } catch {
      return encode(errorScreen("Could not decode action \(actionJSON): \(error)"))
    }
    return encode(Screen(id: screen.id, title: screen.title, components: screen.body()))
  }

  private func errorScreen(_ message: String) -> Screen {
    Screen(id: "error", title: "Error", components: [.text(id: "message", text: message)])
  }

  private func encode(_ value: some Encodable) -> String {
    let encoder = JSONEncoder()
    // Sorted keys keep the output deterministic so tests can pin exact JSON.
    encoder.outputFormatting = [.sortedKeys]
    guard let data = try? encoder.encode(value) else {
      return #"{"id":"error","title":"Error","components":[]}"#
    }
    return String(decoding: data, as: UTF8.self)
  }
}
