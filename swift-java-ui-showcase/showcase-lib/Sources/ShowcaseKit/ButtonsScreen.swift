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

  func reduce(_ action: Action, componentId: String) {
    switch (componentId, action) {
    case ("tap", .tap):
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
      .button(id: "tap", label: "Tap me", role: .primary),
      .button(id: "reset", label: "Reset", role: .secondary),
      .code(
        id: "buttonsCode", title: "Swift code",
        code: #"""
          // body()
          .text(id: "tapCount", text: "Tapped \(tapCount) times")
          .button(id: "tap", label: "Tap me", role: .primary)
          .button(id: "reset", label: "Reset", role: .secondary)

          // reduce(action)
          case ("tap", .tap): tapCount += 1
          case ("reset", .tap): tapCount = 0
          """#),
    ]
  }
}
