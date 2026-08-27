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

/// Selection controls: switch, checkboxes, a radio group, and a segmented
/// control. The summary texts are derived in Swift, showing cross-component
/// state.
final class SelectionScreen: ScreenDefinition {
  let id = "selection"
  let title = "Selection Controls"

  private var wifiOn = true
  private var acceptedTerms = false
  private var subscribed = false
  private var sizeIndex: Int? = 1
  private let sizes = ["Small", "Medium", "Large"]
  private var sortOrder = 0
  private let sortOptions = ["Newest", "Popular"]

  func reduce(_ action: Action, componentId: String) {
    switch (componentId, action) {
    case ("wifi", .setBool(let value)):
      wifiOn = value
    case ("terms", .setBool(let value)):
      acceptedTerms = value
    case ("newsletter", .setBool(let value)):
      subscribed = value
    case ("size", .select(let index)) where sizes.indices.contains(index):
      sizeIndex = index
    case ("sort", .select(let index)) where sortOptions.indices.contains(index):
      sortOrder = index
    default:
      break
    }
  }

  func body() -> [Component] {
    [
      .sectionHeader(id: "switchHeader", text: "Switch"),
      .toggle(id: "wifi", label: "Wi-Fi", isOn: wifiOn),
      .text(id: "wifiStatus", text: "Wi-Fi is \(wifiOn ? "on" : "off")"),
      .code(
        id: "switchCode", title: "Swift code",
        code: #"""
          // body()
          .toggle(id: "wifi", label: "Wi-Fi", isOn: wifiOn)
          .text(id: "wifiStatus", text: "Wi-Fi is \(wifiOn ? "on" : "off")")

          // reduce(action)
          case ("wifi", .setBool(let value)): wifiOn = value
          """#),
      .sectionHeader(id: "checkboxHeader", text: "Checkboxes"),
      .checkbox(id: "terms", label: "Accept the terms", isChecked: acceptedTerms),
      .checkbox(id: "newsletter", label: "Subscribe to the newsletter", isChecked: subscribed),
      .code(
        id: "checkboxCode", title: "Swift code",
        code: #"""
          // body()
          .checkbox(id: "terms", label: "Accept the terms",
            isChecked: acceptedTerms)
          .checkbox(id: "newsletter",
            label: "Subscribe to the newsletter", isChecked: subscribed)

          // reduce(action)
          case ("terms", .setBool(let value)): acceptedTerms = value
          case ("newsletter", .setBool(let value)): subscribed = value
          """#),
      .sectionHeader(id: "radioHeader", text: "Radio group"),
      .radioGroup(id: "size", label: "T-shirt size", options: sizes, selectedIndex: sizeIndex),
      .text(id: "summary", text: "Selected size: \(sizeIndex.map { sizes[$0] } ?? "none")"),
      .code(
        id: "radioCode", title: "Swift code",
        code: #"""
          // body()
          .radioGroup(id: "size", label: "T-shirt size",
            options: sizes, selectedIndex: sizeIndex)
          .text(id: "summary",
            text: "Selected size: \(sizeIndex.map { sizes[$0] } ?? "none")")

          // reduce(action)
          case ("size", .select(let index)): sizeIndex = index
          """#),
      .sectionHeader(id: "segmentedHeader", text: "Segmented control"),
      .segmentedControl(
        id: "sort", label: "Sort by", options: sortOptions, selectedIndex: sortOrder),
      .text(id: "sortSummary", text: "Sorting by: \(sortOptions[sortOrder])"),
      .code(
        id: "segmentedCode", title: "Swift code",
        code: #"""
          // body()
          .segmentedControl(id: "sort", label: "Sort by",
            options: sortOptions, selectedIndex: sortOrder)
          .text(id: "sortSummary",
            text: "Sorting by: \(sortOptions[sortOrder])")

          // reduce(action)
          case ("sort", .select(let index)): sortOrder = index
          """#),
    ]
  }
}
