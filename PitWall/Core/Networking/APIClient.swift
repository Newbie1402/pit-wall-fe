import Foundation

/// Networking layer errors.
enum APIError: Error, Equatable {
    case invalidURL
    case requestFailed(String)
    case decodingFailed(String)
    case httpStatus(Int)
    case notConnected

    var userMessage: String {
        switch self {
        case .invalidURL:
            return "The request could not be built."
        case .requestFailed:
            return "The request could not be completed."
        case .decodingFailed:
            return "The response could not be read."
        case .httpStatus(let status):
            return "The server responded with status \(status)."
        case .notConnected:
            return "You appear to be offline."
        }
    }
}

/// Declarative description of one API call.
///
/// The Go backend will serve these paths; the frontend only ever builds
/// `APIEndpoint` values — it never touches URLs directly in features.
struct APIEndpoint {
    let path: String
    let queryItems: [URLQueryItem]

    init(path: String, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.queryItems = queryItems
    }

    static func season(_ year: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/seasons/\(year)")
    }

    static func race(_ raceID: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/races/\(raceID)")
    }

    static func drivers() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/drivers")
    }

    static func constructors() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/constructors")
    }

    static func standings(year: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/standings", queryItems: [.init(name: "year", value: String(year))])
    }

    static func feed() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/feed")
    }

    static func results(raceID: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/races/\(raceID)/results")
    }
}

/// Transport-agnostic API client. Feature and repository code depends on this
/// protocol, never on `URLSession` directly, so transport can be swapped.
protocol APIClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

/// URLSession-backed client, ready for the Go backend.
///
/// Not used by any mock path yet, but the wiring (base URL, JSON decoding,
/// error mapping) is production-shaped so integration is a configuration
/// change, not a redesign.
struct URLSessionAPIClient: APIClientProtocol {

    let baseURL: URL
    let session: URLSession
    let decoder: JSONDecoder

    init(baseURL: URL = URL(string: "https://api.pitwall.app")!,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeISO8601)
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.path += endpoint.path
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.requestFailed(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.httpStatus(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(String(describing: error))
        }
    }

    /// Backend timestamps are ISO-8601 UTC.
    private static func decodeISO8601(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        if let date = ISO8601DateFormatter.pitwall.date(from: string) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected ISO-8601 UTC timestamp.")
    }
}

private extension ISO8601DateFormatter {
    static let pitwall: ISO8601DateFormatter = {
        let format = ISO8601DateFormatter()
        format.formatOptions = [.withInternetDateTime]
        return format
    }()
}
