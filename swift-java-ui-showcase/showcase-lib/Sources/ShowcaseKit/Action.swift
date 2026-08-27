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

/// A user interaction sent from the Kotlin renderer to Swift, addressed to a
/// component id. The wire format is a JSON object discriminated by `"type"`.
///
/// Named `Action` (rather than, say, `Event`) to match the vocabulary of
/// ReSwift and similar unidirectional-data-flow libraries in the Swift
/// community — see `ScreenDefinition.reduce(_:componentId:)` for the one
/// place this departs from that vocabulary's usual contract.
enum Action: Equatable {
  case tap
  case setBool(Bool)
  case setString(String)
  case setNumber(Double)
  case select(Int)
}

extension Action: Codable {
  private enum CodingKeys: String, CodingKey {
    case type, value, index
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)
    switch type {
    case "tap":
      self = .tap
    case "setBool":
      self = .setBool(try container.decode(Bool.self, forKey: .value))
    case "setString":
      self = .setString(try container.decode(String.self, forKey: .value))
    case "setNumber":
      self = .setNumber(try container.decode(Double.self, forKey: .value))
    case "select":
      self = .select(try container.decode(Int.self, forKey: .index))
    default:
      throw DecodingError.dataCorruptedError(
        forKey: .type, in: container, debugDescription: "Unknown action type: \(type)")
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .tap:
      try container.encode("tap", forKey: .type)
    case .setBool(let value):
      try container.encode("setBool", forKey: .type)
      try container.encode(value, forKey: .value)
    case .setString(let value):
      try container.encode("setString", forKey: .type)
      try container.encode(value, forKey: .value)
    case .setNumber(let value):
      try container.encode("setNumber", forKey: .type)
      try container.encode(value, forKey: .value)
    case .select(let index):
      try container.encode("select", forKey: .type)
      try container.encode(index, forKey: .index)
    }
  }
}
