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

/// Feedback: a display-only progress indicator and an alert. The alert's
/// presence in `body()` *is* its visibility — mirroring how `FormScreen`
/// swaps its whole body on `submitted` — so Swift stays the only owner of
/// whether it's shown, the same as every other screen.
final class FeedbackScreen: ScreenDefinition {
  let id = "feedback"
  let title = "Feedback"

  private var progress = 0.0
  private var showAlert = false
  private var itemStatus = "Nothing deleted yet"

  func reduce(_ action: Action, componentId: String) {
    switch (componentId, action) {
    case ("advance", .tap):
      let next = progress + 0.25
      progress = next > 1.0 ? 0.0 : next
    case ("delete", .tap):
      showAlert = true
    case ("deleteAlert", .select(0)):
      showAlert = false
      itemStatus = "Item deleted"
    case ("deleteAlert", .select(1)):
      showAlert = false
      itemStatus = "Kept the item"
    default:
      break
    }
  }

  func body() -> [Component] {
    var components: [Component] = [
      .sectionHeader(id: "progressHeader", text: "Progress"),
      .text(id: "progressStatus", text: "Progress: \(Int(progress * 100))%"),
      .button(id: "advance", label: "Advance", role: .primary),
      .progressIndicator(id: "loadProgress", label: "Progress", value: progress),
      .code(
        id: "progressCode", title: "Swift code",
        code: #"""
          // body()
          .text(id: "progressStatus",
            text: "Progress: \(Int(progress * 100))%")
          .button(id: "advance", label: "Advance", role: .primary)
          .progressIndicator(id: "loadProgress", label: "Progress",
            value: progress)

          // reduce(action)
          case ("advance", .tap):
            let next = progress + 0.25
            progress = next > 1.0 ? 0.0 : next
          """#),
      .sectionHeader(id: "alertHeader", text: "Alert"),
      .text(id: "itemStatus", text: itemStatus),
      .button(id: "delete", label: "Delete item", role: .secondary),
    ]
    if showAlert {
      components.append(
        .alert(
          id: "deleteAlert", title: "Delete item?", message: "This can't be undone.",
          confirmLabel: "Delete", cancelLabel: "Cancel"))
    }
    components.append(
      .code(
        id: "alertCode", title: "Swift code",
        code: #"""
          // body() (only while showAlert is true)
          .alert(id: "deleteAlert", title: "Delete item?",
            message: "This can't be undone.",
            confirmLabel: "Delete", cancelLabel: "Cancel")

          // reduce(action)
          case ("delete", .tap): showAlert = true
          case ("deleteAlert", .select(0)):
            showAlert = false; itemStatus = "Item deleted"
          case ("deleteAlert", .select(1)):
            showAlert = false; itemStatus = "Kept the item"
          """#))
    return components
  }
}
