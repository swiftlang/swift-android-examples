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

/// Text inputs: one field per keyboard type, with a Swift-computed readout.
final class TextInputsScreen: ScreenDefinition {
  let id = "textInputs"
  let title = "Text Inputs"

  private var plain = ""
  private var email = ""
  private var amount = ""
  private var notes = ""

  func reduce(_ action: Action, componentId: String) {
    switch (componentId, action) {
    case ("plain", .setString(let value)):
      plain = value
    case ("email", .setString(let value)):
      email = value
    case ("amount", .setString(let value)):
      amount = value
    case ("notes", .setString(let value)):
      notes = value
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
      .textEditor(
        id: "notes", label: "Notes", text: notes, placeholder: "Write a few lines"),
      .text(id: "readout", text: "Plain text has \(plain.count) character\(plain.count == 1 ? "" : "s")"),
      .code(
        id: "textInputsCode", title: "Swift code",
        code: #"""
          // body()
          .textField(id: "email", label: "Email", text: email,
            placeholder: "you@example.com", keyboard: .email, error: nil)
          .textEditor(id: "notes", label: "Notes", text: notes,
            placeholder: "Write a few lines")
          .text(id: "readout",
            text: "Plain text has \(plain.count) characters")

          // reduce(action)
          case ("email", .setString(let value)): email = value
          case ("notes", .setString(let value)): notes = value
          """#),
    ]
  }
}
