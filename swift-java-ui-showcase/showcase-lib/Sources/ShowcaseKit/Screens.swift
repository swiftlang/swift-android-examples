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

/// Buttons: a tap counter driven entirely by Swift state.
final class ButtonsScreen: ScreenDefinition {
  let id = "buttons"
  let title = "Buttons"

  private var tapCount = 0

  func handle(_ event: Event, componentId: String) {
    switch (componentId, event) {
    case ("tapMe", .tap):
      tapCount += 1
    case ("reset", .tap):
      tapCount = 0
    default:
      break
    }
  }

  func body() -> [Component] {
    [
      .sectionHeader(id: "header", text: "Buttons"),
      .text(id: "tapCount", text: "Tapped \(tapCount) time\(tapCount == 1 ? "" : "s")"),
      .button(id: "tapMe", label: "Tap me"),
      .button(id: "reset", label: "Reset"),
    ]
  }
}

/// Selection controls: switch, checkboxes, and a radio group. The summary
/// texts are derived in Swift, showing cross-component state.
final class SelectionScreen: ScreenDefinition {
  let id = "selection"
  let title = "Selection Controls"

  private var wifiOn = true
  private var acceptedTerms = false
  private var subscribed = false
  private var sizeIndex: Int? = 1
  private let sizes = ["Small", "Medium", "Large"]

  func handle(_ event: Event, componentId: String) {
    switch (componentId, event) {
    case ("wifi", .setBool(let value)):
      wifiOn = value
    case ("terms", .setBool(let value)):
      acceptedTerms = value
    case ("newsletter", .setBool(let value)):
      subscribed = value
    case ("size", .select(let index)) where sizes.indices.contains(index):
      sizeIndex = index
    default:
      break
    }
  }

  func body() -> [Component] {
    [
      .sectionHeader(id: "switchHeader", text: "Switch"),
      .toggle(id: "wifi", label: "Wi-Fi", isOn: wifiOn),
      .text(id: "wifiStatus", text: "Wi-Fi is \(wifiOn ? "on" : "off")"),
      .sectionHeader(id: "checkboxHeader", text: "Checkboxes"),
      .checkbox(id: "terms", label: "Accept the terms", isChecked: acceptedTerms),
      .checkbox(id: "newsletter", label: "Subscribe to the newsletter", isChecked: subscribed),
      .sectionHeader(id: "radioHeader", text: "Radio group"),
      .radioGroup(id: "size", label: "T-shirt size", options: sizes, selectedIndex: sizeIndex),
      .text(id: "summary", text: "Selected size: \(sizeIndex.map { sizes[$0] } ?? "none")"),
    ]
  }
}

/// Sliders: the value readouts are formatted by Swift on every change.
final class SlidersScreen: ScreenDefinition {
  let id = "sliders"
  let title = "Sliders"

  private var volume = 0.5
  private var brightness = 80.0

  func handle(_ event: Event, componentId: String) {
    switch (componentId, event) {
    case ("volume", .setNumber(let value)):
      volume = value
    case ("brightness", .setNumber(let value)):
      brightness = value
    default:
      break
    }
  }

  func body() -> [Component] {
    [
      .sectionHeader(id: "header", text: "Sliders"),
      .slider(id: "volume", label: "Volume: \(Int(volume * 100))%", value: volume, min: 0, max: 1),
      .slider(
        id: "brightness", label: "Brightness: \(Int(brightness))", value: brightness, min: 0,
        max: 100),
    ]
  }
}

/// Text inputs: one field per keyboard type, with a Swift-computed readout.
final class TextInputsScreen: ScreenDefinition {
  let id = "textInputs"
  let title = "Text Inputs"

  private var plain = ""
  private var email = ""
  private var amount = ""

  func handle(_ event: Event, componentId: String) {
    switch (componentId, event) {
    case ("plain", .setString(let value)):
      plain = value
    case ("email", .setString(let value)):
      email = value
    case ("amount", .setString(let value)):
      amount = value
    default:
      break
    }
  }

  func body() -> [Component] {
    [
      .sectionHeader(id: "header", text: "Text inputs"),
      .textField(
        id: "plain", label: "Plain text", text: plain, placeholder: "Type anything",
        keyboard: .text, error: nil),
      .textField(
        id: "email", label: "Email", text: email, placeholder: "you@example.com",
        keyboard: .email, error: nil),
      .textField(
        id: "amount", label: "Amount", text: amount, placeholder: "0",
        keyboard: .number, error: nil),
      .text(id: "readout", text: "Plain text has \(plain.count) character\(plain.count == 1 ? "" : "s")"),
    ]
  }
}

/// Pure validation rules used by `FormScreen`. Kept free of state so the
/// Swift tests can pin them directly.
enum Validation {
  static func requiredField(_ value: String, name: String) -> String? {
    value.allSatisfy(\.isWhitespace) ? "\(name) is required" : nil
  }

  static func email(_ value: String) -> String? {
    if let error = requiredField(value, name: "Email") { return error }
    let parts = value.split(separator: "@")
    guard parts.count == 2, parts[1].contains(".") else {
      return "Enter a valid email address"
    }
    return nil
  }

  static func age(_ value: String) -> String? {
    if let error = requiredField(value, name: "Age") { return error }
    guard let age = Int(value), (1...130).contains(age) else {
      return "Enter an age between 1 and 130"
    }
    return nil
  }
}

/// A small form: Swift stores the field values, validates on submit, and
/// swaps the body for a success message when validation passes.
final class FormScreen: ScreenDefinition {
  let id = "form"
  let title = "Form & Validation"

  private var name = ""
  private var email = ""
  private var age = ""
  private var errors: [String: String] = [:]
  private var submitted = false

  func handle(_ event: Event, componentId: String) {
    switch (componentId, event) {
    case ("name", .setString(let value)):
      name = value
      errors["name"] = nil
    case ("email", .setString(let value)):
      email = value
      errors["email"] = nil
    case ("age", .setString(let value)):
      age = value
      errors["age"] = nil
    case ("submit", .tap):
      errors = validate()
      submitted = errors.isEmpty
    case ("reset", .tap):
      (name, email, age, errors, submitted) = ("", "", "", [:], false)
    default:
      break
    }
  }

  private func validate() -> [String: String] {
    var errors: [String: String] = [:]
    errors["name"] = Validation.requiredField(name, name: "Name")
    errors["email"] = Validation.email(email)
    errors["age"] = Validation.age(age)
    return errors.compactMapValues { $0 }
  }

  func body() -> [Component] {
    if submitted {
      return [
        .sectionHeader(id: "header", text: "Form & Validation"),
        .text(id: "success", text: "Thanks, \(name)! Your form was submitted."),
        .button(id: "reset", label: "Start over"),
      ]
    }
    return [
      .sectionHeader(id: "header", text: "Form & Validation"),
      .textField(
        id: "name", label: "Name", text: name, placeholder: "Grace Hopper",
        keyboard: .text, error: errors["name"]),
      .textField(
        id: "email", label: "Email", text: email, placeholder: "you@example.com",
        keyboard: .email, error: errors["email"]),
      .textField(
        id: "age", label: "Age", text: age, placeholder: "42",
        keyboard: .number, error: errors["age"]),
      .button(id: "submit", label: "Submit"),
    ]
  }
}
