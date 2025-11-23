//
//  empty.swift
//  SwiftHashing
//
//  Created by Mads on 23/11/2025.
//

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
        // Use the base URL for the Open-Meteo API.
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
    public func getWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        let location = self.locationFetcher.currentLocation()
        let response = try await client.getV1Forecast(.init(query: .init(latitude: location.latitude, longitude: location.longitude, currentWeather: true)))

        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let forecast):
                guard let current = forecast.currentWeather else {
                    throw WeatherError.unexpectedResponse
                }

                // Map the generated schema type to our clean, public `WeatherData` type.
                return WeatherData(
                    temperature: current.temperature,
                    windSpeed: current.windSpeed,
                    windDirection: current.windDirection
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
