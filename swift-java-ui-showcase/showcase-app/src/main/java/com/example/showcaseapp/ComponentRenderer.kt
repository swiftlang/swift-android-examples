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

package com.example.showcaseapp

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import org.json.JSONObject

/**
 * The generic interpreter for ShowcaseKit's component model: one Material 3
 * composable per `"kind"` the Swift library can declare. All state shown
 * here comes from the Swift-provided JSON; every interaction is reported
 * back to Swift through [onEvent] and re-rendered from Swift's response.
 */
@Composable
fun ComponentView(component: JSONObject, onEvent: (componentId: String, event: JSONObject) -> Unit) {
    val id = component.getString("id")
    when (val kind = component.getString("kind")) {
        "sectionHeader" -> Text(
            text = component.getString("text"),
            style = MaterialTheme.typography.titleMedium
        )

        "text" -> Text(
            text = component.getString("text"),
            style = MaterialTheme.typography.bodyLarge
        )

        "button" -> Button(onClick = { onEvent(id, event("tap")) }) {
            Text(component.getString("label"))
        }

        "toggle" -> Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(component.getString("label"))
            Switch(
                checked = component.getBoolean("isOn"),
                onCheckedChange = { onEvent(id, event("setBool").put("value", it)) }
            )
        }

        "checkbox" -> Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(
                checked = component.getBoolean("isChecked"),
                onCheckedChange = { onEvent(id, event("setBool").put("value", it)) }
            )
            Text(component.getString("label"))
        }

        "radioGroup" -> Column {
            Text(component.getString("label"))
            val options = component.getJSONArray("options")
            val selectedIndex = component.optInt("selectedIndex", -1)
            for (index in 0 until options.length()) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    RadioButton(
                        selected = index == selectedIndex,
                        onClick = { onEvent(id, event("select").put("index", index)) }
                    )
                    Text(options.getString(index))
                }
            }
        }

        "slider" -> Column {
            Text(component.getString("label"))
            Slider(
                value = component.getDouble("value").toFloat(),
                valueRange = component.getDouble("min").toFloat()..component.getDouble("max").toFloat(),
                onValueChange = { onEvent(id, event("setNumber").put("value", it.toDouble())) }
            )
        }

        "textField" -> TextFieldView(component, id, onEvent)

        else -> Text("Unknown component kind: $kind")
    }
}

@Composable
private fun TextFieldView(
    component: JSONObject,
    id: String,
    onEvent: (componentId: String, event: JSONObject) -> Unit
) {
    // Buffer the in-flight text locally, re-seeding only when the
    // Swift-provided value changes. Feeding every dispatched round trip
    // straight back into the field would fight the IME cursor.
    val swiftText = component.getString("text")
    var localText by remember(swiftText) { mutableStateOf(swiftText) }
    val error = if (component.isNull("error")) null else component.getString("error")

    OutlinedTextField(
        value = localText,
        onValueChange = {
            localText = it
            onEvent(id, event("setString").put("value", it))
        },
        label = { Text(component.getString("label")) },
        placeholder = { Text(component.getString("placeholder")) },
        isError = error != null,
        supportingText = { error?.let { Text(it) } },
        keyboardOptions = KeyboardOptions(
            keyboardType = when (component.getString("keyboard")) {
                "email" -> KeyboardType.Email
                "number" -> KeyboardType.Number
                else -> KeyboardType.Text
            }
        ),
        modifier = Modifier.fillMaxWidth()
    )
}

private fun event(type: String) = JSONObject().put("type", type)
