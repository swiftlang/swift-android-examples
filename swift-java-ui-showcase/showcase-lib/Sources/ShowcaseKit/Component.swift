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

/// The keyboard type a text field asks the Android IME for.
enum Keyboard: String, Codable {
  case text
  case email
  case number
}

/// A single UI component declared by Swift and rendered by the Kotlin/Compose
/// interpreter in `showcase-app`.
///
/// Each case maps to exactly one Material 3 composable on the Kotlin side.
/// The wire format is a flat JSON object discriminated by a `"kind"` key —
/// see the schema table in `swift-java-ui-showcase/README.md`.
enum Component: Equatable {
  case sectionHeader(id: String, text: String)
  case text(id: String, text: String)
  case button(id: String, label: String)
  case toggle(id: String, label: String, isOn: Bool)
  case checkbox(id: String, label: String, isChecked: Bool)
  case radioGroup(id: String, label: String, options: [String], selectedIndex: Int?)
  case slider(id: String, label: String, value: Double, min: Double, max: Double)
  case textField(
    id: String, label: String, text: String, placeholder: String,
    keyboard: Keyboard, error: String?)
}

extension Component: Codable {
  private enum CodingKeys: String, CodingKey {
    case kind, id, text, label, isOn, isChecked, options, selectedIndex
    case value, min, max, placeholder, keyboard, error
  }

  /// The stable identifier events are addressed to.
  var id: String {
    switch self {
    case .sectionHeader(let id, _), .text(let id, _), .button(let id, _):
      return id
    case .toggle(let id, _, _), .checkbox(let id, _, _):
      return id
    case .radioGroup(let id, _, _, _):
      return id
    case .slider(let id, _, _, _, _):
      return id
    case .textField(let id, _, _, _, _, _):
      return id
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .sectionHeader(let id, let text):
      try container.encode("sectionHeader", forKey: .kind)
      try container.encode(id, forKey: .id)
      try container.encode(text, forKey: .text)
    case .text(let id, let text):
      try container.encode("text", forKey: .kind)
      try container.encode(id, forKey: .id)
      try container.encode(text, forKey: .text)
    case .button(let id, let label):
      try container.encode("button", forKey: .kind)
      try container.encode(id, forKey: .id)
      try container.encode(label, forKey: .label)
    case .toggle(let id, let label, let isOn):
      try container.encode("toggle", forKey: .kind)
      try container.encode(id, forKey: .id)
      try container.encode(label, forKey: .label)
      try container.encode(isOn, forKey: .isOn)
    case .checkbox(let id, let label, let isChecked):
      try container.encode("checkbox", forKey: .kind)
      try container.encode(id, forKey: .id)
      try container.encode(label, forKey: .label)
      try container.encode(isChecked, forKey: .isChecked)
    case .radioGroup(let id, let label, let options, let selectedIndex):
      try container.encode("radioGroup", forKey: .kind)
      try container.encode(id, forKey: .id)
      try container.encode(label, forKey: .label)
      try container.encode(options, forKey: .options)
      try container.encode(selectedIndex, forKey: .selectedIndex)
    case .slider(let id, let label, let value, let min, let max):
      try container.encode("slider", forKey: .kind)
      try container.encode(id, forKey: .id)
      try container.encode(label, forKey: .label)
      try container.encode(value, forKey: .value)
      try container.encode(min, forKey: .min)
      try container.encode(max, forKey: .max)
    case .textField(let id, let label, let text, let placeholder, let keyboard, let error):
      try container.encode("textField", forKey: .kind)
      try container.encode(id, forKey: .id)
      try container.encode(label, forKey: .label)
      try container.encode(text, forKey: .text)
      try container.encode(placeholder, forKey: .placeholder)
      try container.encode(keyboard, forKey: .keyboard)
      try container.encode(error, forKey: .error)
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(String.self, forKey: .kind)
    switch kind {
    case "sectionHeader":
      self = .sectionHeader(
        id: try container.decode(String.self, forKey: .id),
        text: try container.decode(String.self, forKey: .text))
    case "text":
      self = .text(
        id: try container.decode(String.self, forKey: .id),
        text: try container.decode(String.self, forKey: .text))
    case "button":
      self = .button(
        id: try container.decode(String.self, forKey: .id),
        label: try container.decode(String.self, forKey: .label))
    case "toggle":
      self = .toggle(
        id: try container.decode(String.self, forKey: .id),
        label: try container.decode(String.self, forKey: .label),
        isOn: try container.decode(Bool.self, forKey: .isOn))
    case "checkbox":
      self = .checkbox(
        id: try container.decode(String.self, forKey: .id),
        label: try container.decode(String.self, forKey: .label),
        isChecked: try container.decode(Bool.self, forKey: .isChecked))
    case "radioGroup":
      self = .radioGroup(
        id: try container.decode(String.self, forKey: .id),
        label: try container.decode(String.self, forKey: .label),
        options: try container.decode([String].self, forKey: .options),
        selectedIndex: try container.decodeIfPresent(Int.self, forKey: .selectedIndex))
    case "slider":
      self = .slider(
        id: try container.decode(String.self, forKey: .id),
        label: try container.decode(String.self, forKey: .label),
        value: try container.decode(Double.self, forKey: .value),
        min: try container.decode(Double.self, forKey: .min),
        max: try container.decode(Double.self, forKey: .max))
    case "textField":
      self = .textField(
        id: try container.decode(String.self, forKey: .id),
        label: try container.decode(String.self, forKey: .label),
        text: try container.decode(String.self, forKey: .text),
        placeholder: try container.decode(String.self, forKey: .placeholder),
        keyboard: try container.decode(Keyboard.self, forKey: .keyboard),
        error: try container.decodeIfPresent(String.self, forKey: .error))
    default:
      throw DecodingError.dataCorruptedError(
        forKey: .kind, in: container, debugDescription: "Unknown component kind: \(kind)")
    }
  }
}
