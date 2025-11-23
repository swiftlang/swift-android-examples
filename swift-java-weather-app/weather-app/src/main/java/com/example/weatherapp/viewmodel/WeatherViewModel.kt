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
import androidx.lifecycle.viewModelScope
import com.example.weatherapp.data.WeatherData
import com.example.weatherapp.services.LocationService
import com.example.weatherlib.WeatherClient
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import org.swift.swiftkit.core.SwiftArena

class WeatherViewModel(application: Application) : AndroidViewModel(application) {
    private val arena = SwiftArena.ofAuto()

    private val locationService = LocationService(application)
    private val weatherClient = WeatherClient.init(locationService, arena)

    private val _weatherData = MutableStateFlow<WeatherData?>(null)
    val weatherData = _weatherData.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error = _error.asStateFlow()

    fun fetchWeather() {
        viewModelScope.launch {
            try {
                    var weather = weatherClient.getWeather(arena).get()
                    _weatherData.value = WeatherData(
                        temperature = weather.temperature,
                        windSpeed = weather.windSpeed,
                        windDirection = weather.windDirection
                    )
            } catch (e: Exception) {
                Log.i("app", "crash?")
                _error.value = "An unexpected error occurred: ${e.message}"
            }
        }
    }
}
