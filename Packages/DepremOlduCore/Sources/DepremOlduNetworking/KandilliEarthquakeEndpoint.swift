import Foundation

public enum KandilliEarthquakeEndpointError: Error, Equatable, Sendable {
    case invalidSkip
    case invalidLimit
    case unableToEncodeBody
}

public enum KandilliEarthquakeEndpoint {
    public static let host = "api.orhanaydogdu.com.tr"
    public static let path = "/deprem/data/search"
    public static let maximumResponseBodyBytes = 16 * 1_024 * 1_024
    public static let provider = "kandilli"
    public static let sort = "date_-1"

    public static func makeRequest(skip: Int, limit: Int) throws -> HTTPRequest {
        guard skip >= 0 else { throw KandilliEarthquakeEndpointError.invalidSkip }
        guard limit > 0 else { throw KandilliEarthquakeEndpointError.invalidLimit }

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        guard let url = components.url else {
            throw KandilliEarthquakeEndpointError.unableToEncodeBody
        }

        let body: Data
        do {
            body = try JSONEncoder().encode(
                SearchBody(
                    provider: provider,
                    sort: sort,
                    skip: skip,
                    limit: limit
                )
            )
        } catch {
            throw KandilliEarthquakeEndpointError.unableToEncodeBody
        }

        return HTTPRequest(
            url: url,
            method: .post,
            headers: [
                "Content-Type": "application/json",
                "Accept": "application/json",
            ],
            body: body,
            maximumResponseBodyBytes: maximumResponseBodyBytes
        )
    }

    private struct SearchBody: Encodable {
        let provider: String
        let sort: String
        let skip: Int
        let limit: Int
    }
}
