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

/// One screen of the showcase: an identity, a title, an event handler, and a
/// declarative body. Conforming types own their screen's state.
///
/// To add a new screen, conform to this protocol and append an instance to
/// `ShowcaseStore.shared` — no Kotlin changes are needed; the navigation
/// graph is data-driven from this registry.
protocol ScreenDefinition: AnyObject {
  var id: String { get }
  var title: String { get }
  func handle(_ event: Event, componentId: String)
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

/// The registry of showcase screens and the single place state is read and
/// mutated. All entry points are called from the Android main thread — that
/// invariant is what makes the unsynchronized singleton safe.
final class ShowcaseStore {
  static let shared = ShowcaseStore()

  private let screens: [any ScreenDefinition]

  init(screens: [any ScreenDefinition] = ShowcaseStore.defaultScreens()) {
    self.screens = screens
  }

  static func defaultScreens() -> [any ScreenDefinition] {
    [
      ButtonsScreen(),
      SelectionScreen(),
      SlidersScreen(),
      TextInputsScreen(),
      FormScreen(),
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

  func dispatch(screenId: String, componentId: String, eventJSON: String) -> String {
    guard let screen = screens.first(where: { $0.id == screenId }) else {
      return encode(errorScreen("Unknown screen: \(screenId)"))
    }
    do {
      let event = try JSONDecoder().decode(Event.self, from: Data(eventJSON.utf8))
      screen.handle(event, componentId: componentId)
    } catch {
      return encode(errorScreen("Could not decode event \(eventJSON): \(error)"))
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
