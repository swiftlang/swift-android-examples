public enum WeatherError: Error {
    case apiError(String)
    case unexpectedResponse

    public var description: String {
        switch self {
        case .apiError(let message):
            return "API Error: \(message)"
        case .unexpectedResponse:
            return "The server returned an invalid or unexpected response."
        }
    }
}
