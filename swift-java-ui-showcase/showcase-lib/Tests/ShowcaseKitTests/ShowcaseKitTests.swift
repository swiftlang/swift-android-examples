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

import Testing

@testable import ShowcaseKit

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

// Pins the exact wire format of the buttons screen. This is the JSON schema
// contract documented in swift-java-ui-showcase/README.md ("JSON schema"
// section) — if this test needs updating, update that table too.
@Test func buttonsScreenSchemaIsStable() {
  let store = ShowcaseStore()
  #expect(
    store.screenJSON("buttons") == #"""
      {"components":[{"id":"header","kind":"sectionHeader","text":"Buttons"},{"id":"tapCount","kind":"text","text":"Tapped 0 times"},{"id":"tapMe","kind":"button","label":"Tap me"},{"id":"reset","kind":"button","label":"Reset"}],"id":"buttons","title":"Buttons"}
      """#)
}

@Test func screenListContainsAllScreensInOrder() throws {
  let store = ShowcaseStore()
  let list = try JSONDecoder().decode(ScreenList.self, from: Data(store.screensJSON().utf8))
  #expect(list.screens.map(\.id) == ["buttons", "selection", "sliders", "textInputs", "form"])
}

@Test(arguments: [
  (#"{"type":"tap"}"#, Event.tap),
  (#"{"type":"setBool","value":true}"#, Event.setBool(true)),
  (#"{"type":"setString","value":"abc"}"#, Event.setString("abc")),
  (#"{"type":"setNumber","value":0.75}"#, Event.setNumber(0.75)),
  (#"{"type":"select","index":2}"#, Event.select(2)),
])
func eventDecoding(json: String, expected: Event) throws {
  #expect(try JSONDecoder().decode(Event.self, from: Data(json.utf8)) == expected)
}

@Test func tapDispatchRoundTrip() throws {
  let store = ShowcaseStore()
  let updated = store.dispatch(
    screenId: "buttons", componentId: "tapMe", eventJSON: #"{"type":"tap"}"#)
  let screen = try JSONDecoder().decode(Screen.self, from: Data(updated.utf8))
  #expect(screen.components.contains(.text(id: "tapCount", text: "Tapped 1 time")))

  let reset = store.dispatch(
    screenId: "buttons", componentId: "reset", eventJSON: #"{"type":"tap"}"#)
  let resetScreen = try JSONDecoder().decode(Screen.self, from: Data(reset.utf8))
  #expect(resetScreen.components.contains(.text(id: "tapCount", text: "Tapped 0 times")))
}

@Test func unknownScreenReturnsErrorScreen() throws {
  let store = ShowcaseStore()
  let screen = try JSONDecoder().decode(Screen.self, from: Data(store.screenJSON("nope").utf8))
  #expect(screen.id == "error")
}

@Test func validationRules() {
  #expect(Validation.requiredField("  ", name: "Name") == "Name is required")
  #expect(Validation.requiredField("Grace", name: "Name") == nil)
  #expect(Validation.email("not-an-email") == "Enter a valid email address")
  #expect(Validation.email("grace@example.com") == nil)
  #expect(Validation.age("0") == "Enter an age between 1 and 130")
  #expect(Validation.age("42") == nil)
}

@Test func formSubmitWithErrorsThenSuccess() throws {
  let store = ShowcaseStore()
  let decoder = JSONDecoder()

  // Submitting the empty form must surface an error on every field.
  let invalid = store.dispatch(
    screenId: "form", componentId: "submit", eventJSON: #"{"type":"tap"}"#)
  let invalidScreen = try decoder.decode(Screen.self, from: Data(invalid.utf8))
  let fieldErrors = invalidScreen.components.compactMap { component -> String? in
    if case .textField(_, _, _, _, _, let error) = component { return error }
    return nil
  }
  #expect(fieldErrors.count == 3)

  // Filling every field and resubmitting swaps the body for the success state.
  for (id, value) in [("name", "Grace"), ("email", "grace@example.com"), ("age", "42")] {
    _ = store.dispatch(
      screenId: "form", componentId: id,
      eventJSON: #"{"type":"setString","value":"\#(value)"}"#)
  }
  let valid = store.dispatch(
    screenId: "form", componentId: "submit", eventJSON: #"{"type":"tap"}"#)
  let validScreen = try decoder.decode(Screen.self, from: Data(valid.utf8))
  #expect(
    validScreen.components.contains(
      .text(id: "success", text: "Thanks, Grace! Your form was submitted.")))
}
