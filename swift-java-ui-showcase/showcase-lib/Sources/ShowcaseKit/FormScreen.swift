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

  func reduce(_ action: Action, componentId: String) {
    switch (componentId, action) {
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
        .button(id: "reset", label: "Start over", role: .primary),
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
      .button(id: "submit", label: "Submit", role: .primary),
      .code(
        id: "formCode", title: "Swift code",
        code: #"""
          // body()
          .textField(id: "email", label: "Email", text: email,
            placeholder: "you@example.com", keyboard: .email,
            error: errors["email"])
          .button(id: "submit", label: "Submit", role: .primary)

          // reduce(action)
          case ("submit", .tap):
            errors = validate()
            submitted = errors.isEmpty

          // validate() builds on pure rules in `Validation`
          errors["email"] = Validation.email(email)
          """#),
    ]
  }
}
