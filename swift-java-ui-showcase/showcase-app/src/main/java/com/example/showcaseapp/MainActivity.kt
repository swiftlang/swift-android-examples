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

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.showcaseapp.ui.theme.ShowcaseAppTheme
import com.example.showcasekit.ShowcaseKit
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ShowcaseAppTheme {
                ShowcaseNavHost()
            }
        }
    }
}

/**
 * The navigation graph is data-driven: the list of destinations comes from
 * Swift's screen registry, so adding a screen in ShowcaseKit requires no
 * change on the Kotlin side.
 */
@Composable
fun ShowcaseNavHost() {
    val navController = rememberNavController()
    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            HomeScreen(onOpenScreen = { navController.navigate("screen/$it") })
        }
        composable("screen/{screenId}") { backStackEntry ->
            ShowcaseScreen(
                screenId = backStackEntry.arguments?.getString("screenId").orEmpty(),
                onBack = { navController.popBackStack() }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(onOpenScreen: (String) -> Unit) {
    // This calls the Swift function `showcaseScreens` from ShowcaseAPI.swift.
    val screens = remember { JSONObject(ShowcaseKit.showcaseScreens()).getJSONArray("screens") }

    Scaffold(topBar = { TopAppBar(title = { Text("UI Showcase") }) }) { padding ->
        LazyColumn(modifier = Modifier.fillMaxSize().padding(padding)) {
            items(count = screens.length()) { index ->
                val screen = screens.getJSONObject(index)
                ListItem(
                    headlineContent = { Text(screen.getString("title")) },
                    modifier = Modifier.clickable { onOpenScreen(screen.getString("id")) }
                )
                HorizontalDivider()
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShowcaseScreen(screenId: String, onBack: () -> Unit) {
    // Swift is the single source of truth: this holds only the latest JSON
    // returned by ShowcaseKit, and every event replaces it wholesale.
    var screen by remember {
        // This calls the Swift function `showcaseScreen` from ShowcaseAPI.swift.
        mutableStateOf(JSONObject(ShowcaseKit.showcaseScreen(screenId)))
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(screen.getString("title")) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        // Sections aren't a wire concept — Swift only ever emits a flat
        // component list. Every screen happens to start each section with a
        // `sectionHeader`, so grouping on that boundary here is enough to
        // give each section its own visually distinct card.
        val sections = groupIntoSections(screen.getJSONArray("components"))
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            items(count = sections.size) { index ->
                val section = sections[index]
                // The header and its code snippet move into one top row —
                // title leading, the snippet's info icon trailing — instead
                // of flowing through the section like an ordinary component.
                val header = section.firstOrNull { it.getString("kind") == "sectionHeader" }
                val codeSnippet = section.firstOrNull { it.getString("kind") == "code" }
                val bodyComponents = section.filterNot { it === header || it === codeSnippet }

                OutlinedCard(modifier = Modifier.fillMaxWidth()) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            val headerText = header?.getString("text").orEmpty()
                            Text(text = headerText, style = MaterialTheme.typography.titleMedium)
                            if (codeSnippet != null) {
                                CodeSnippetView(codeSnippet, sectionTitle = headerText)
                            }
                        }
                        for (component in bodyComponents) {
                            ComponentView(component) { componentId, event ->
                                // This calls the Swift function
                                // `showcaseDispatch` from ShowcaseAPI.swift;
                                // Swift handles the event and returns the
                                // screen's new component tree.
                                screen = JSONObject(
                                    ShowcaseKit.showcaseDispatch(screenId, componentId, event.toString())
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/** Splits a flat component list into sections, starting a new one at every `sectionHeader`. */
private fun groupIntoSections(components: JSONArray): List<List<JSONObject>> {
    val sections = mutableListOf<MutableList<JSONObject>>()
    for (index in 0 until components.length()) {
        val component = components.getJSONObject(index)
        if (sections.isEmpty() || component.getString("kind") == "sectionHeader") {
            sections.add(mutableListOf())
        }
        sections.last().add(component)
    }
    return sections
}
