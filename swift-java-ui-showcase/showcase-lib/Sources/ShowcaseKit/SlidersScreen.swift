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

/// Sliders: the value readouts are formatted by Swift on every change.
final class SlidersScreen: ScreenDefinition {
  let id = "sliders"
  let title = "Sliders"

  private var volume = 0.5
  private var brightness = 80.0

  func reduce(_ action: Action, componentId: String) {
    switch (componentId, action) {
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
      .code(
        id: "slidersCode", title: "Swift code",
        code: #"""
          // body()
          .slider(id: "volume", label: "Volume: \(Int(volume * 100))%",
            value: volume, min: 0, max: 1)
          .slider(id: "brightness",
            label: "Brightness: \(Int(brightness))",
            value: brightness, min: 0, max: 100)

          // reduce(action)
          case ("volume", .setNumber(let value)): volume = value
          case ("brightness", .setNumber(let value)): brightness = value
          """#),
    ]
  }
}
