//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

package com.example.weatherapp.viewmodel

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.application
import androidx.lifecycle.viewModelScope
import com.example.weatherapp.services.LocationService
import com.example.weatherlib.WeatherClient
import com.example.weatherlib.WeatherData
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.future.await
import kotlinx.coroutines.launch
import org.swift.swiftkit.core.SwiftArena

class WeatherViewModel(application: Application) : AndroidViewModel(application) {
    private val arena = SwiftArena.ofAuto()

    private val _weatherData = MutableStateFlow<WeatherData?>(null)
    val weatherData = _weatherData.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error = _error.asStateFlow()

    fun fetchWeather() {
        viewModelScope.launch {
            try {
                val locationService = LocationService(application)
                val weatherClient = WeatherClient.init(locationService, arena)
                val weather = weatherClient.getWeather(arena).await()
                _weatherData.value = weather
            } catch (e: Exception) {
                _error.value = "An unexpected error occurred: ${e.message}"
            }
        }
    }
}
