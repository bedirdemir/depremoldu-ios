import Foundation
import DepremOlduDomain

public enum KandilliEarthquakeServiceError: Error, Equatable, Sendable {
    case endpoint(KandilliEarthquakeEndpointError)
    case transport(HTTPTransportError)
    case unacceptableStatus(code: Int, retryAfter: TimeInterval?)
    case malformedPayload
    case unexpected
}

public struct KandilliEarthquakePage: Sendable {
    public let items: [KandilliEarthquakeDTO]
    public let rawResponseBody: Data

    public init(items: [KandilliEarthquakeDTO], rawResponseBody: Data) {
        self.items = items
        self.rawResponseBody = rawResponseBody
    }
}

public protocol KandilliEarthquakeServiceProviding: Sendable {
    func fetchPage(skip: Int, limit: Int) async throws -> KandilliEarthquakePage
    func decodePage(_ body: Data) throws -> [KandilliEarthquakeDTO]
}

public struct KandilliEarthquakeService: KandilliEarthquakeServiceProviding {
    private let client: any HTTPClient

    public init(client: any HTTPClient) {
        self.client = client
    }

    public func fetchPage(skip: Int, limit: Int) async throws -> KandilliEarthquakePage {
        let request: HTTPRequest
        do {
            request = try KandilliEarthquakeEndpoint.makeRequest(skip: skip, limit: limit)
        } catch let error as KandilliEarthquakeEndpointError {
            throw KandilliEarthquakeServiceError.endpoint(error)
        } catch {
            throw KandilliEarthquakeServiceError.unexpected
        }

        let response: HTTPResponse
        do {
            response = try await client.send(request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as HTTPTransportError {
            throw KandilliEarthquakeServiceError.transport(error)
        } catch {
            throw KandilliEarthquakeServiceError.unexpected
        }

        guard response.statusCode == 200 else {
            throw KandilliEarthquakeServiceError.unacceptableStatus(
                code: response.statusCode,
                retryAfter: Self.retryAfterSeconds(from: response)
            )
        }

        let items = try decodePage(response.body)
        return KandilliEarthquakePage(items: items, rawResponseBody: response.body)
    }

    public func decodePage(_ body: Data) throws -> [KandilliEarthquakeDTO] {
        let response: KandilliEarthquakeSearchResponseDTO
        do {
            response = try JSONDecoder().decode(
                KandilliEarthquakeSearchResponseDTO.self,
                from: body
            )
        } catch {
            throw KandilliEarthquakeServiceError.malformedPayload
        }
        return response.result ?? []
    }

    private static func retryAfterSeconds(from response: HTTPResponse) -> TimeInterval? {
        guard let rawValue = response.headerValue(for: "Retry-After"),
              let seconds = TimeInterval(rawValue),
              seconds >= 0 else {
            return nil
        }
        return seconds
    }
}
