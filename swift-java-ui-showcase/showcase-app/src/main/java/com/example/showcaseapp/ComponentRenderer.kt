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

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Checkbox
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
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

        "button" -> when (component.getString("role")) {
            "secondary" -> OutlinedButton(onClick = { onEvent(id, event("tap")) }) {
                Text(component.getString("label"))
            }
            else -> Button(onClick = { onEvent(id, event("tap")) }) {
                Text(component.getString("label"))
            }
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

        "segmentedControl" -> Column {
            Text(component.getString("label"))
            val options = component.getJSONArray("options")
            val selectedIndex = component.getInt("selectedIndex")
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                for (index in 0 until options.length()) {
                    SegmentedButton(
                        selected = index == selectedIndex,
                        onClick = { onEvent(id, event("select").put("index", index)) },
                        shape = SegmentedButtonDefaults.itemShape(index, options.length())
                    ) {
                        Text(options.getString(index))
                    }
                }
            }
        }

        "progressIndicator" -> Column {
            Text(component.getString("label"))
            val value = component.getDouble("value").toFloat()
            LinearProgressIndicator(
                progress = { value },
                modifier = Modifier.fillMaxWidth()
            )
        }

        "alert" -> AlertDialog(
            onDismissRequest = { onEvent(id, event("select").put("index", 1)) },
            title = { Text(component.getString("title")) },
            text = { Text(component.getString("message")) },
            confirmButton = {
                TextButton(onClick = { onEvent(id, event("select").put("index", 0)) }) {
                    Text(component.getString("confirmLabel"))
                }
            },
            dismissButton = {
                TextButton(onClick = { onEvent(id, event("select").put("index", 1)) }) {
                    Text(component.getString("cancelLabel"))
                }
            }
        )

        "slider" -> Column {
            Text(component.getString("label"))
            Slider(
                value = component.getDouble("value").toFloat(),
                valueRange = component.getDouble("min").toFloat()..component.getDouble("max").toFloat(),
                onValueChange = { onEvent(id, event("setNumber").put("value", it.toDouble())) }
            )
        }

        "stepper" -> Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(component.getString("label"))
            val value = component.getInt("value")
            val min = component.getInt("min")
            val max = component.getInt("max")
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(
                    onClick = { onEvent(id, event("setNumber").put("value", -1)) },
                    enabled = value > min
                ) { Text("−", style = MaterialTheme.typography.titleLarge) }
                Text(
                    text = value.toString(),
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(horizontal = 12.dp)
                )
                IconButton(
                    onClick = { onEvent(id, event("setNumber").put("value", 1)) },
                    enabled = value < max
                ) { Text("+", style = MaterialTheme.typography.titleLarge) }
            }
        }

        "datePicker" -> DatePickerView(component, id, onEvent)

        "textField" -> TextFieldView(component, id, onEvent)

        "textEditor" -> TextEditorView(component, id, onEvent)

        "code" -> CodeSnippetView(component, sectionTitle = component.getString("title"))

        else -> Text("Unknown component kind: $kind")
    }
}

/**
 * An info icon that opens the Swift source driving the section it sits in,
 * in a fullscreen modal. Placed at the top-trailing corner of each section
 * card by [ShowcaseScreen] — its position is what identifies which section
 * it belongs to, so no label is needed here. Whether the modal is open never
 * round-trips through Swift: like scroll position, it is presentation-only
 * state, so it stays Kotlin-local while all app state remains Swift-owned.
 */
@Composable
fun CodeSnippetView(component: JSONObject, sectionTitle: String) {
    var showModal by remember { mutableStateOf(false) }
    IconButton(onClick = { showModal = true }) {
        Icon(
            imageVector = Icons.Filled.Info,
            contentDescription = "View Swift code for $sectionTitle",
            tint = MaterialTheme.colorScheme.primary
        )
    }
    if (showModal) {
        CodeSnippetDialog(
            title = component.getString("title"),
            code = component.getString("code"),
            onDismiss = { showModal = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CodeSnippetDialog(title: String, code: String, onDismiss: () -> Unit) {
    val clipboard = LocalClipboardManager.current
    val context = LocalContext.current
    var wrapEnabled by remember { mutableStateOf(false) }

    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Scaffold(
            modifier = Modifier.fillMaxSize(),
            topBar = {
                TopAppBar(
                    title = { Text(title) },
                    navigationIcon = {
                        IconButton(onClick = onDismiss) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Close")
                        }
                    },
                    actions = {
                        TextButton(onClick = { wrapEnabled = !wrapEnabled }) {
                            Text(if (wrapEnabled) "No wrap" else "Wrap")
                        }
                        TextButton(onClick = {
                            clipboard.setText(AnnotatedString(code))
                            Toast.makeText(context, "Copied to clipboard", Toast.LENGTH_SHORT).show()
                        }) {
                            Text("Copy")
                        }
                    }
                )
            }
        ) { padding ->
            // Long lines either scroll horizontally (default, so the Swift
            // indentation stays intact) or wrap to the modal's width,
            // toggled by the "Wrap" action above. Wrap state is
            // presentation-only, so it stays local like `showModal`.
            val verticalScroll = rememberScrollState()
            val horizontalScroll = rememberScrollState()
            var codeModifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .verticalScroll(verticalScroll)
            if (!wrapEnabled) {
                codeModifier = codeModifier.horizontalScroll(horizontalScroll)
            }
            Text(
                text = code,
                style = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace),
                modifier = codeModifier.padding(16.dp)
            )
        }
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

/**
 * A button showing the selected date; tapping it opens Material 3's calendar
 * dialog. The wire value is a plain "yyyy-MM-dd" string — the same `setString`
 * action every other text-bearing component already dispatches.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DatePickerView(
    component: JSONObject,
    id: String,
    onEvent: (componentId: String, event: JSONObject) -> Unit
) {
    var showPicker by remember { mutableStateOf(false) }
    val label = component.getString("label")
    val dateText = component.getString("text")

    OutlinedButton(onClick = { showPicker = true }, modifier = Modifier.fillMaxWidth()) {
        Text("$label: $dateText")
    }

    if (showPicker) {
        val initialMillis = runCatching {
            LocalDate.parse(dateText).atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
        }.getOrNull()
        val state = rememberDatePickerState(initialSelectedDateMillis = initialMillis)
        DatePickerDialog(
            onDismissRequest = { showPicker = false },
            confirmButton = {
                TextButton(onClick = {
                    showPicker = false
                    state.selectedDateMillis?.let { millis ->
                        val isoDate = Instant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate()
                        onEvent(id, event("setString").put("value", isoDate.toString()))
                    }
                }) { Text("OK") }
            },
            dismissButton = {
                TextButton(onClick = { showPicker = false }) { Text("Cancel") }
            }
        ) {
            DatePicker(state = state)
        }
    }
}

/** A multi-line text area — SwiftUI's TextEditor to [TextFieldView]'s TextField. */
@Composable
private fun TextEditorView(
    component: JSONObject,
    id: String,
    onEvent: (componentId: String, event: JSONObject) -> Unit
) {
    // Same IME-buffering pattern as TextFieldView.
    val swiftText = component.getString("text")
    var localText by remember(swiftText) { mutableStateOf(swiftText) }

    OutlinedTextField(
        value = localText,
        onValueChange = {
            localText = it
            onEvent(id, event("setString").put("value", it))
        },
        label = { Text(component.getString("label")) },
        placeholder = { Text(component.getString("placeholder")) },
        minLines = 4,
        modifier = Modifier.fillMaxWidth()
    )
}

private fun event(type: String) = JSONObject().put("type", type)
