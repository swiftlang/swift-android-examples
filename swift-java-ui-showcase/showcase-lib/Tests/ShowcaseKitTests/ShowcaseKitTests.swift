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
  let store = ScreenRegistry()
  #expect(
    store.screenJSON("buttons") == #"""
      {"components":[{"id":"header","kind":"sectionHeader","text":"Buttons"},{"id":"tapCount","kind":"text","text":"Tapped 0 times"},{"id":"tap","kind":"button","label":"Tap me","role":"primary"},{"id":"reset","kind":"button","label":"Reset","role":"secondary"},{"code":"\/\/ body()\n.text(id: \"tapCount\", text: \"Tapped \\(tapCount) times\")\n.button(id: \"tap\", label: \"Tap me\", role: .primary)\n.button(id: \"reset\", label: \"Reset\", role: .secondary)\n\n\/\/ reduce(action)\ncase (\"tap\", .tap): tapCount += 1\ncase (\"reset\", .tap): tapCount = 0","id":"buttonsCode","kind":"code","title":"Swift code"}],"id":"buttons","title":"Buttons"}
      """#)
}

// Every section header is paired with exactly one code snippet showing the
// Swift that drives that section.
@Test(arguments: ["buttons", "selection", "sliders", "textInputs", "pickers", "form", "feedback"])
func everySectionHasACodeSnippet(screenId: String) throws {
  let store = ScreenRegistry()
  let screen = try JSONDecoder().decode(Screen.self, from: Data(store.screenJSON(screenId).utf8))
  let headerCount = screen.components.count { if case .sectionHeader = $0 { true } else { false } }
  let snippets = screen.components.compactMap { component -> String? in
    if case .code(_, _, let code) = component { return code }
    return nil
  }
  #expect(snippets.count == headerCount)
  #expect(snippets.allSatisfy { !$0.isEmpty })
}

@Test func stepperComponentRoundTripsThroughJSON() throws {
  let component = Component.stepper(id: "quantity", label: "Quantity", value: 3, min: 0, max: 10)
  let encoded = try JSONEncoder().encode(component)
  #expect(try JSONDecoder().decode(Component.self, from: encoded) == component)
}

@Test func datePickerComponentRoundTripsThroughJSON() throws {
  let component = Component.datePicker(id: "birthday", label: "Birthday", date: "2000-01-01")
  let encoded = try JSONEncoder().encode(component)
  #expect(try JSONDecoder().decode(Component.self, from: encoded) == component)
}

@Test func pickersScreenStepperClampsToRange() throws {
  let store = ScreenRegistry()
  let decoder = JSONDecoder()

  // Decrementing from the default (3) five times clamps at the minimum (0).
  var latest: Screen!
  for _ in 0..<5 {
    let updated = store.dispatch(
      screenId: "pickers", componentId: "quantity", actionJSON: #"{"type":"setNumber","value":-1}"#)
    latest = try decoder.decode(Screen.self, from: Data(updated.utf8))
  }
  #expect(
    latest.components.contains(.stepper(id: "quantity", label: "Quantity", value: 0, min: 0, max: 10)))
}

@Test func pickersScreenDatePickerDispatchesSetString() throws {
  let store = ScreenRegistry()
  let updated = store.dispatch(
    screenId: "pickers", componentId: "birthday",
    actionJSON: #"{"type":"setString","value":"1990-05-12"}"#)
  let screen = try JSONDecoder().decode(Screen.self, from: Data(updated.utf8))
  #expect(
    screen.components.contains(.datePicker(id: "birthday", label: "Birthday", date: "1990-05-12")))
}

@Test func segmentedControlComponentRoundTripsThroughJSON() throws {
  let component = Component.segmentedControl(
    id: "sort", label: "Sort by", options: ["Newest", "Popular"], selectedIndex: 0)
  let encoded = try JSONEncoder().encode(component)
  #expect(try JSONDecoder().decode(Component.self, from: encoded) == component)
}

@Test func selectionScreenSegmentedControlDispatchesSelect() throws {
  let store = ScreenRegistry()
  let updated = store.dispatch(
    screenId: "selection", componentId: "sort", actionJSON: #"{"type":"select","index":1}"#)
  let screen = try JSONDecoder().decode(Screen.self, from: Data(updated.utf8))
  #expect(
    screen.components.contains(
      .segmentedControl(
        id: "sort", label: "Sort by", options: ["Newest", "Popular"], selectedIndex: 1)))
}

@Test func progressIndicatorComponentRoundTripsThroughJSON() throws {
  let component = Component.progressIndicator(id: "loadProgress", label: "Progress", value: 0.5)
  let encoded = try JSONEncoder().encode(component)
  #expect(try JSONDecoder().decode(Component.self, from: encoded) == component)
}

@Test func alertComponentRoundTripsThroughJSON() throws {
  let component = Component.alert(
    id: "deleteAlert", title: "Delete item?", message: "This can't be undone.",
    confirmLabel: "Delete", cancelLabel: "Cancel")
  let encoded = try JSONEncoder().encode(component)
  #expect(try JSONDecoder().decode(Component.self, from: encoded) == component)
}

@Test func feedbackScreenAdvancesProgressAndWraps() throws {
  let store = ScreenRegistry()
  let decoder = JSONDecoder()

  var latest: Screen!
  for expected in [0.25, 0.5, 0.75, 1.0, 0.0] {
    let updated = store.dispatch(
      screenId: "feedback", componentId: "advance", actionJSON: #"{"type":"tap"}"#)
    latest = try decoder.decode(Screen.self, from: Data(updated.utf8))
    #expect(
      latest.components.contains(
        .progressIndicator(id: "loadProgress", label: "Progress", value: expected)))
  }
}

@Test func feedbackScreenAlertConfirmAndCancel() throws {
  let store = ScreenRegistry()
  let decoder = JSONDecoder()

  // Deleting shows the alert.
  let afterDelete = store.dispatch(
    screenId: "feedback", componentId: "delete", actionJSON: #"{"type":"tap"}"#)
  let deleteScreen = try decoder.decode(Screen.self, from: Data(afterDelete.utf8))
  #expect(
    deleteScreen.components.contains(
      .alert(
        id: "deleteAlert", title: "Delete item?", message: "This can't be undone.",
        confirmLabel: "Delete", cancelLabel: "Cancel")))

  // Cancelling hides the alert and leaves the item.
  let afterCancel = store.dispatch(
    screenId: "feedback", componentId: "deleteAlert", actionJSON: #"{"type":"select","index":1}"#)
  let cancelScreen = try decoder.decode(Screen.self, from: Data(afterCancel.utf8))
  #expect(!cancelScreen.components.contains { if case .alert = $0 { true } else { false } })
  #expect(cancelScreen.components.contains(.text(id: "itemStatus", text: "Kept the item")))

  // Deleting again, then confirming, hides the alert and marks it deleted.
  _ = store.dispatch(screenId: "feedback", componentId: "delete", actionJSON: #"{"type":"tap"}"#)
  let afterConfirm = store.dispatch(
    screenId: "feedback", componentId: "deleteAlert", actionJSON: #"{"type":"select","index":0}"#)
  let confirmScreen = try decoder.decode(Screen.self, from: Data(afterConfirm.utf8))
  #expect(!confirmScreen.components.contains { if case .alert = $0 { true } else { false } })
  #expect(confirmScreen.components.contains(.text(id: "itemStatus", text: "Item deleted")))
}

@Test(arguments: [ButtonRole.primary, ButtonRole.secondary])
func buttonComponentRoundTripsThroughJSON(role: ButtonRole) throws {
  let component = Component.button(id: "go", label: "Go", role: role)
  let encoded = try JSONEncoder().encode(component)
  let decoded = try JSONDecoder().decode(Component.self, from: encoded)
  #expect(decoded == component)
  let json = try JSONDecoder().decode([String: String].self, from: encoded)
  #expect(json["role"] == role.rawValue)
}

@Test func buttonsScreenAssignsPrimaryAndSecondaryRoles() throws {
  let store = ScreenRegistry()
  let screen = try JSONDecoder().decode(Screen.self, from: Data(store.screenJSON("buttons").utf8))
  #expect(screen.components.contains(.button(id: "tap", label: "Tap me", role: .primary)))
  #expect(screen.components.contains(.button(id: "reset", label: "Reset", role: .secondary)))
}

@Test func codeComponentRoundTripsThroughJSON() throws {
  let component = Component.code(
    id: "switchCode", title: "Switch",
    code: #".toggle(id: "wifi", label: "Wi-Fi", isOn: wifiOn)"#)
  let encoded = try JSONEncoder().encode(component)
  let kind = try JSONDecoder().decode([String: String].self, from: encoded)["kind"]
  #expect(kind == "code")
  #expect(try JSONDecoder().decode(Component.self, from: encoded) == component)
}

@Test func textEditorComponentRoundTripsThroughJSON() throws {
  let component = Component.textEditor(
    id: "notes", label: "Notes", text: "Hello", placeholder: "Write something long")
  let encoded = try JSONEncoder().encode(component)
  let kind = try JSONDecoder().decode([String: String].self, from: encoded)["kind"]
  #expect(kind == "textEditor")
  #expect(try JSONDecoder().decode(Component.self, from: encoded) == component)
}

@Test func textInputsScreenEditsNotesThroughTextEditor() throws {
  let store = ScreenRegistry()
  let updated = store.dispatch(
    screenId: "textInputs", componentId: "notes",
    actionJSON: #"{"type":"setString","value":"Dear diary"}"#)
  let screen = try JSONDecoder().decode(Screen.self, from: Data(updated.utf8))
  #expect(
    screen.components.contains(
      .textEditor(
        id: "notes", label: "Notes", text: "Dear diary",
        placeholder: "Write a few lines")))
}

@Test func screenListContainsAllScreensInOrder() throws {
  let store = ScreenRegistry()
  let list = try JSONDecoder().decode(ScreenList.self, from: Data(store.screensJSON().utf8))
  #expect(
    list.screens.map(\.id)
      == ["buttons", "selection", "sliders", "textInputs", "pickers", "form", "feedback"])
}

@Test(arguments: [
  (#"{"type":"tap"}"#, Action.tap),
  (#"{"type":"setBool","value":true}"#, Action.setBool(true)),
  (#"{"type":"setString","value":"abc"}"#, Action.setString("abc")),
  (#"{"type":"setNumber","value":0.75}"#, Action.setNumber(0.75)),
  (#"{"type":"select","index":2}"#, Action.select(2)),
])
func actionDecoding(json: String, expected: Action) throws {
  #expect(try JSONDecoder().decode(Action.self, from: Data(json.utf8)) == expected)
}

@Test func tapDispatchRoundTrip() throws {
  let store = ScreenRegistry()
  let updated = store.dispatch(
    screenId: "buttons", componentId: "tap", actionJSON: #"{"type":"tap"}"#)
  let screen = try JSONDecoder().decode(Screen.self, from: Data(updated.utf8))
  #expect(screen.components.contains(.text(id: "tapCount", text: "Tapped 1 time")))

  let reset = store.dispatch(
    screenId: "buttons", componentId: "reset", actionJSON: #"{"type":"tap"}"#)
  let resetScreen = try JSONDecoder().decode(Screen.self, from: Data(reset.utf8))
  #expect(resetScreen.components.contains(.text(id: "tapCount", text: "Tapped 0 times")))
}

@Test func unknownScreenReturnsErrorScreen() throws {
  let store = ScreenRegistry()
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
  let store = ScreenRegistry()
  let decoder = JSONDecoder()

  // Submitting the empty form must surface an error on every field.
  let invalid = store.dispatch(
    screenId: "form", componentId: "submit", actionJSON: #"{"type":"tap"}"#)
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
      actionJSON: #"{"type":"setString","value":"\#(value)"}"#)
  }
  let valid = store.dispatch(
    screenId: "form", componentId: "submit", actionJSON: #"{"type":"tap"}"#)
  let validScreen = try decoder.decode(Screen.self, from: Data(valid.utf8))
  #expect(
    validScreen.components.contains(
      .text(id: "success", text: "Thanks, Grace! Your form was submitted.")))
}
