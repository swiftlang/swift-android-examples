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

/// Pickers: controls whose value comes from a bounded set or a calendar,
/// rather than free-form typing — kept separate from Text Inputs since a
/// stepper or a date picker isn't a text field.
final class PickersScreen: ScreenDefinition {
  let id = "pickers"
  let title = "Pickers"

  private var quantity = 3
  private var birthday = "2000-01-01"

  func reduce(_ action: Action, componentId: String) {
    switch (componentId, action) {
    case ("quantity", .setNumber(let delta)):
      quantity = max(0, min(10, quantity + Int(delta)))
    case ("birthday", .setString(let value)):
      birthday = value
    default:
      break
    }
  }

  func body() -> [Component] {
    [
      .sectionHeader(id: "stepperHeader", text: "Stepper"),
      .stepper(id: "quantity", label: "Quantity", value: quantity, min: 0, max: 10),
      .text(id: "quantitySummary", text: "Quantity: \(quantity)"),
      .code(
        id: "stepperCode", title: "Swift code",
        code: #"""
          // body()
          .stepper(id: "quantity", label: "Quantity",
            value: quantity, min: 0, max: 10)
          .text(id: "quantitySummary", text: "Quantity: \(quantity)")

          // reduce(action)
          case ("quantity", .setNumber(let delta)):
            quantity = max(0, min(10, quantity + Int(delta)))
          """#),
      .sectionHeader(id: "dateHeader", text: "Date picker"),
      .datePicker(id: "birthday", label: "Birthday", date: birthday),
      .text(id: "birthdaySummary", text: "Selected date: \(birthday)"),
      .code(
        id: "dateCode", title: "Swift code",
        code: #"""
          // body()
          .datePicker(id: "birthday", label: "Birthday", date: birthday)
          .text(id: "birthdaySummary", text: "Selected date: \(birthday)")

          // reduce(action)
          case ("birthday", .setString(let value)): birthday = value
          """#),
    ]
  }
}
