import Foundation

protocol TempStickServiceProtocol {
  func validateApiKey(_ apiKey: String) async throws -> Bool
  func fetchSensors(apiKey: String) async throws -> [TempStickSensor]
  func fetchLatestReading(sensorId: String, apiKey: String) async throws -> TempStickReading
  func fetchReadings(sensorId: String, apiKey: String) async throws
    -> [TempStickReading]
}

enum TempStickError: Error, LocalizedError {
  case invalidURL
  case invalidAPIKey
  case invalidStatusCode(Int)
  case noData
  case decodingFailed(Error)
  case requestFailed(Error)
  case apiError(String)
  case networkUnavailable

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .invalidAPIKey:
      return "Invalid or missing API key"
    case .invalidStatusCode(let code):
      return "HTTP Error: \(code)"
    case .noData:
      return "No data received"
    case .decodingFailed(let error):
      return "Data parsing failed: \(error.localizedDescription)"
    case .requestFailed(let error):
      return "Request failed: \(error.localizedDescription)"
    case .apiError(let message):
      return "API Error: \(message)"
    case .networkUnavailable:
      return "Network unavailable"
    }
  }
}

class TempStickService: TempStickServiceProtocol {
  private let baseURL = "https://tempstickapi.com/api/v1"
  private let session: URLSession

  init(session: URLSession? = nil) {
    if let session = session {
      self.session = session
    } else {
      let config = URLSessionConfiguration.default
      config.timeoutIntervalForRequest = 30.0
      config.timeoutIntervalForResource = 600.0
      self.session = URLSession(configuration: config)
    }
  }

  func validateApiKey(_ apiKey: String) async throws -> Bool {
    do {
      _ = try await fetchSensors(apiKey: apiKey)
      return true
    } catch {
      if case TempStickError.invalidAPIKey = error {
        return false
      }
      throw error
    }
  }

  func fetchSensors(apiKey: String) async throws -> [TempStickSensor] {
    guard let url = URL(string: "\(baseURL)/sensors/all") else {
      throw TempStickError.invalidURL
    }

    let request = buildAuthenticatedGetRequest(url: url, apiKey: apiKey)

    do {
      let (data, response) = try await session.data(for: request)

      try validateResponse(response)

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      let sensors =
        try decoder
        .decode(TempStickApiResponse<SensorsResponse>.self, from: data)
        .data.items

      return sensors

    } catch let error as DecodingError {
      throw TempStickError.decodingFailed(error)
    } catch {
      if error is TempStickError {
        throw error
      }
      throw TempStickError.requestFailed(error)
    }
  }

  func fetchLatestReading(sensorId: String, apiKey: String) async throws -> TempStickReading {
    let readings = try await fetchReadings(sensorId: sensorId, apiKey: apiKey)
    guard let latest = readings.max(by: { $0.sensorTime < $1.sensorTime }) else {
      throw TempStickError.noData
    }
    return latest
  }

  func fetchReadings(sensorId: String, apiKey: String) async throws
    -> [TempStickReading]
  {
    var urlString = "\(baseURL)/sensor/\(sensorId)/readings"

    guard let url = URL(string: urlString) else {
      throw TempStickError.invalidURL
    }

    let request = buildAuthenticatedGetRequest(url: url, apiKey: apiKey)

    do {
      let (data, response) = try await session.data(for: request)
      try validateResponse(response)

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .formatted(.tempStick)

      let readings =
        try decoder
        .decode(TempStickApiResponse<ReadingsResponse>.self, from: data)
        .data.readings

      return readings

    } catch let error as DecodingError {
      throw TempStickError.decodingFailed(error)
    } catch {
      if error is TempStickError {
        throw error
      }
      throw TempStickError.requestFailed(error)
    }

  }

  func buildAuthenticatedGetRequest(
    url: URL,
    apiKey: String,
    query: [String: String]? = nil,
    extraHeaders: [String: String] = [:]
  ) -> URLRequest {
    var finalURL = url
    if let query, var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
      comps.queryItems =
        (comps.queryItems ?? []) + query.map { URLQueryItem(name: $0.key, value: $0.value) }
      finalURL = comps.url ?? url
    }

    var request = URLRequest(url: finalURL)
    request.httpMethod = "GET"
    request.setValue("", forHTTPHeaderField: "User-Agent")  // matches: curl -A ""
    request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")  // matches: curl --header 'X-API-KEY: ...'
    extraHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
    return request
  }

  func buildAuthenticatedPostRequest(
    url: URL,
    apiKey: String,
    jsonBody: Any,  // e.g. [String: Any] or Encodable-encoded dict
    extraHeaders: [String: String] = [:]
  ) throws -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("", forHTTPHeaderField: "User-Agent")
    request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Encode JSON body
    request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
    extraHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
    return request
  }

  private func validateResponse(_ response: URLResponse) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw TempStickError.invalidStatusCode(-1)
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
        throw TempStickError.invalidAPIKey
      }
      throw TempStickError.invalidStatusCode(httpResponse.statusCode)
    }
  }
}

extension DateFormatter {
  fileprivate static let tempStick: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = TimeZone(secondsFromGMT: 0)
    df.dateFormat = "yyyy-MM-dd HH:mm:ssX"  // handles trailing Z or offsets
    return df
  }()
}
