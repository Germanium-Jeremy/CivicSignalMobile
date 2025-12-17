import Foundation

final class APIClient {
   static let shared = APIClient()

   private let session: URLSession
   private let baseURL: URL
   private let jsonDecoder = JSONDecoder()

   private init() {
       let configuration = URLSessionConfiguration.default
       configuration.timeoutIntervalForRequest = APIConfig.timeout
       configuration.timeoutIntervalForResource = APIConfig.timeout
       session = URLSession(configuration: configuration)
       baseURL = APIConfig.baseURL
       jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
       jsonDecoder.dateDecodingStrategy = .iso8601
   }

   // Generic request helper for decodable responses (no query items)
   func request<T: Decodable>(
       _ path: String,
       method: String = "GET",
       body: Encodable? = nil,
       authorized: Bool = true,
       responseType: T.Type
   ) async throws -> T {
       let data = try await performRequest(path: path, method: method, queryItems: nil, body: body, authorized: authorized)
       return try jsonDecoder.decode(T.self, from: data)
   }

   // Generic request helper with URL query items
   func request<T: Decodable>(
       _ path: String,
       method: String = "GET",
       queryItems: [URLQueryItem]?,
       body: Encodable? = nil,
       authorized: Bool = true,
       responseType: T.Type
   ) async throws -> T {
       let data = try await performRequest(path: path, method: method, queryItems: queryItems, body: body, authorized: authorized)
       return try jsonDecoder.decode(T.self, from: data)
   }
   
   // Request helper that returns raw data
    func performRequest(
       path: String,
       method: String = "GET",
       queryItems: [URLQueryItem]? = nil,
       body: Encodable? = nil,
       authorized: Bool = true
   ) async throws -> Data {
       // Build initial request
       let makeURLRequest: () throws -> URLRequest = {
           var components = URLComponents(url: self.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
           components?.queryItems = queryItems
           guard let url = components?.url else { throw URLError(.badURL) }
           var req = URLRequest(url: url)
           req.httpMethod = method
           req.setValue("application/json", forHTTPHeaderField: "Content-Type")
           if authorized, let token = TokenManager.accessToken {
               req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
           }
           if let body = body {
               let encoder = JSONEncoder()
               req.httpBody = try encoder.encode(AnyEncodable(body))
           }
           return req
       }

       // First attempt
       var request = try makeURLRequest()
       var (data, response) = try await session.data(for: request)

       // Check response
       if let http = response as? HTTPURLResponse, http.statusCode == 401, authorized {
           // Try to refresh token and retry once
           let refreshed = try await self.refreshAccessToken()
           if refreshed {
               // Retry with new token
               request = try makeURLRequest()
               (data, response) = try await session.data(for: request)
           }
       }

       guard let http = response as? HTTPURLResponse else {
           throw URLError(.badServerResponse)
       }

       guard (200..<300).contains(http.statusCode) else {
           throw APIError.httpStatus(code: http.statusCode, data: data)
       }

       return data
   }
   
   // Request helper that returns a dictionary
   func requestDictionary(
       _ path: String,
       method: String = "GET",
       body: Encodable? = nil,
       authorized: Bool = true
   ) async throws -> [String: Any] {
       let data = try await performRequest(path: path, method: method, queryItems: nil, body: body, authorized: authorized)
       guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
           throw NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response as dictionary"])
       }
       return json
   }
}

// Simple wrapper so we can encode `Encodable` as `AnyEncodable`
private struct AnyEncodable: Encodable {
   private let encodeFunc: (Encoder) throws -> Void

   init(_ encodable: Encodable) {
       self.encodeFunc = encodable.encode
   }

   func encode(to encoder: Encoder) throws {
       try encodeFunc(encoder)
   }
}

enum APIError: Error {
   case httpStatus(code: Int, data: Data)
}

// MARK: - Token refresh support

private extension APIClient {
   struct RefreshResponse: Decodable {
       struct Tokens: Decodable { let accessToken: String; let refreshToken: String }
       let tokens: Tokens?
       let success: Bool?
       let error: String?
   }

   func refreshAccessToken() async throws -> Bool {
       guard let refresh = TokenManager.refreshToken else { return false }

       var req = URLRequest(url: baseURL.appendingPathComponent("auth/refresh"))
       req.httpMethod = "POST"
       req.setValue("application/json", forHTTPHeaderField: "Content-Type")
       let body = ["refreshToken": refresh]
       req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

       do {
           let (data, response) = try await session.data(for: req)
           guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
               return false
           }
           let res = try jsonDecoder.decode(RefreshResponse.self, from: data)
           if let t = res.tokens {
               TokenManager.saveTokens(accessToken: t.accessToken, refreshToken: t.refreshToken)
               return true
           }
           return false
       } catch {
           return false
       }
   }
}
