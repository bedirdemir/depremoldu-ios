import Foundation
import DepremOlduDomain
import DepremOlduNetworking
import Testing

@Suite("Kandilli endpoint")
struct KandilliEarthquakeEndpointTests {
    @Test("Request is a JSON POST to the search endpoint")
    func request() throws {
        let request = try KandilliEarthquakeEndpoint.makeRequest(skip: 100, limit: 100)
        #expect(request.url.absoluteString == "https://api.orhanaydogdu.com.tr/deprem/data/search")
        #expect(request.method == .post)
        #expect(request.headers["Content-Type"] == "application/json")
        #expect(request.maximumResponseBodyBytes == KandilliEarthquakeEndpoint.maximumResponseBodyBytes)

        let body = try #require(request.body)
        let object = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(object["provider"] as? String == "kandilli")
        #expect(object["sort"] as? String == "date_-1")
        #expect(object["skip"] as? Int == 100)
        #expect(object["limit"] as? Int == 100)
    }

    @Test("Invalid skip and limit are rejected")
    func validation() {
        #expect(throws: KandilliEarthquakeEndpointError.invalidSkip) {
            _ = try KandilliEarthquakeEndpoint.makeRequest(skip: -1, limit: 100)
        }
        #expect(throws: KandilliEarthquakeEndpointError.invalidLimit) {
            _ = try KandilliEarthquakeEndpoint.makeRequest(skip: 0, limit: 0)
        }
    }
}

@Suite("Kandilli decoding and mapping")
struct KandilliEarthquakeDecodingTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }

    @Test("Search response maps real provider fields")
    func happyPath() throws {
        let items = try JSONDecoder().decode(
            KandilliEarthquakeSearchResponseDTO.self,
            from: fixture("search-response")
        ).result ?? []
        #expect(items.count == 3)

        let first = KandilliEarthquakeMapper.map(try #require(items.first))
        #expect(first.id == "ClPx8QiI47G3g")
        #expect(first.provider == "kandilli")
        #expect(first.region == "SUGUL-DARENDE (MALATYA)")
        #expect(first.magnitude == 2)
        #expect(first.formattedMagnitude == "2.0")
        #expect(first.depth == 5.3)
        #expect(first.formattedDepth == "5.3")
        #expect(first.displayDate == "2026.09.11")
        #expect(first.displayTime == "23:24:22")
        #expect(first.coordinate?.latitude == 38.43)
        #expect(first.coordinate?.longitude == 37.5222)
        #expect(first.occurredAt != nil)
    }

    @Test("Non-array result degrades to an empty list like the web")
    func nonArrayResult() throws {
        let items = try JSONDecoder().decode(
            KandilliEarthquakeSearchResponseDTO.self,
            from: fixture("search-result-object")
        ).result
        #expect(items == nil)
    }

    @Test("Numeric strings decode lossily like Number() in the web")
    func lossyValues() throws {
        let items = try JSONDecoder().decode(
            KandilliEarthquakeSearchResponseDTO.self,
            from: fixture("search-lossy-values")
        ).result ?? []
        let mapped = KandilliEarthquakeMapper.map(try #require(items.first))
        #expect(mapped.magnitude == 4.5)
        #expect(mapped.depth == 7.5)
        #expect(mapped.coordinate?.latitude == 39.5)
        #expect(mapped.coordinate?.longitude == 30.5)
    }

    @Test("Missing fields fall back to web defaults")
    func missingFields() {
        let item = KandilliEarthquakeDTO(
            earthquakeID: nil,
            provider: nil,
            title: nil,
            magnitude: nil,
            depth: nil,
            geojson: nil,
            dateTime: nil,
            locationTimeZone: nil
        )
        let mapped = KandilliEarthquakeMapper.map(item)
        #expect(mapped.id == "")
        #expect(mapped.provider == "kandilli")
        #expect(mapped.region == "-")
        #expect(mapped.magnitude == 0)
        #expect(mapped.depth == nil)
        #expect(mapped.displayDate == "-")
        #expect(mapped.displayTime == "-")
        #expect(mapped.occurredAt == nil)
        #expect(mapped.coordinate == nil)
    }

    @Test("Malformed JSON is a typed payload failure")
    func malformedPayload() {
        let service = KandilliEarthquakeService(
            client: StubHTTPClient(
                response: HTTPResponse(statusCode: 200, headers: [:], body: Data("{".utf8))
            )
        )
        #expect(throws: KandilliEarthquakeServiceError.malformedPayload) {
            _ = try service.decodePage(Data("{".utf8))
        }
    }
}

@Suite("Kandilli service")
struct KandilliEarthquakeServiceTests {
    private func responseBody() throws -> Data {
        let url = try #require(Bundle.module.url(forResource: "search-response", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    @Test("Exact 200 decodes the page and keeps the raw body")
    func success() async throws {
        let body = try responseBody()
        let client = StubHTTPClient(
            response: HTTPResponse(statusCode: 200, headers: [:], body: body)
        )
        let service = KandilliEarthquakeService(client: client)
        let page = try await service.fetchPage(skip: 0, limit: 100)
        #expect(page.items.count == 3)
        #expect(page.rawResponseBody == body)
    }

    @Test("Non-200 status is rejected with Retry-After metadata")
    func statusRejection() async throws {
        let client = StubHTTPClient(
            response: HTTPResponse(
                statusCode: 503,
                headers: ["Retry-After": "30"],
                body: Data()
            )
        )
        let service = KandilliEarthquakeService(client: client)
        await #expect(throws: KandilliEarthquakeServiceError.unacceptableStatus(code: 503, retryAfter: 30)) {
            _ = try await service.fetchPage(skip: 0, limit: 100)
        }
    }

    @Test("Transport failures keep their typed classification")
    func transportFailure() async {
        let client = StubHTTPClient(error: HTTPTransportError.timedOut)
        let service = KandilliEarthquakeService(client: client)
        await #expect(throws: KandilliEarthquakeServiceError.transport(.timedOut)) {
            _ = try await service.fetchPage(skip: 0, limit: 100)
        }
    }
}

struct StubHTTPClient: HTTPClient {
    let response: HTTPResponse?
    let error: HTTPTransportError?

    init(response: HTTPResponse? = nil, error: HTTPTransportError? = nil) {
        self.response = response
        self.error = error
    }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        if let error {
            throw error
        }
        guard let response else {
            throw HTTPTransportError.unexpected
        }
        return response
    }
}
