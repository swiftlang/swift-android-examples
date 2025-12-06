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

#if os(Android)
import OpenAPIAsyncHTTPClient
#else
import OpenAPIURLSession
#endif
import OpenAPIRuntime
import Foundation

public final class WeatherClient {
    private let client: Client
    private let locationFetcher: any LocationFetcher

    public init(locationFetcher: any LocationFetcher) {
        guard let serverURL = URL(string: "https://api.open-meteo.com") else {
            fatalError("Could not create server URL.")
        }

        self.locationFetcher = locationFetcher
        self.client = Client(
            serverURL: serverURL,
            transport: WeatherClient.makeTransport()
        )
    }

    /// Fetches the current weather for a specific geographic location.
    public func getWeather() async throws -> WeatherData {
        let location = self.locationFetcher.currentLocation()
        let response = try await client.getV1Forecast(.init(query: .init(latitude: location.latitude, longitude: location.longitude, currentWeather: true)))

        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let forecast):
                guard let current = forecast.currentWeather else {
                    throw WeatherError.unexpectedResponse
                }

                return WeatherData(
                    temperature: current.temperature,
                    windSpeed: current.windspeed,
                    windDirection: current.winddirection
                )
            }

        default:
            throw WeatherError.apiError("Received an API error: \(response)")
        }
    }

    private static func makeTransport() -> some ClientTransport {
#if os(Android)
        return AsyncHTTPClientTransport(configuration: .init())
#else
        return URLSessionTransport()
#endif
    }
}
