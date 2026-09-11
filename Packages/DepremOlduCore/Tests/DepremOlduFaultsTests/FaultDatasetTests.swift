import Foundation
import DepremOlduDomain
import DepremOlduFaults
import Testing

@Suite("Fault dataset decoding")
struct FaultDatasetDecoderTests {
    private func fixtureData() throws -> Data {
        let url = try #require(Bundle.module.url(forResource: "faults-sample", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    @Test("Valid lines decode with confidence, rate and coordinates")
    func decoding() throws {
        let dataset = try FaultDatasetJSONDecoder().decode(try fixtureData())
        #expect(dataset.version == 1)
        #expect(dataset.source == "GINRAS/AFEAD")
        #expect(dataset.lines.count == 4)

        let first = try #require(dataset.lines.first)
        #expect(first.name == "PLINY TRENCH f.z.")
        #expect(first.confidence == .a)
        #expect(first.rate == .one)
        #expect(first.coordinates.count == 3)
        #expect(first.coordinates[0].latitude == 34.3146)
        #expect(first.coordinates[0].longitude == 25.5299)
    }

    @Test("Invalid confidence and rate fall back to C/3 like the web")
    func fallbackClassifiers() throws {
        let dataset = try FaultDatasetJSONDecoder().decode(try fixtureData())
        let unknown = try #require(dataset.lines.first { $0.name == nil })
        #expect(unknown.confidence == .c)
        #expect(unknown.rate == .three)
    }

    @Test("Lines with fewer than two valid coordinates are dropped")
    func droppedLines() throws {
        let dataset = try FaultDatasetJSONDecoder().decode(try fixtureData())
        #expect(dataset.lines.contains { $0.name == "SINGLE POINT" } == false)
    }

    @Test("Missing confidence defaults and malformed payload is typed")
    func malformed() throws {
        let dataset = try FaultDatasetJSONDecoder().decode(try fixtureData())
        let missing = try #require(dataset.lines.first { $0.name == "MISSING CONFIDENCE" })
        #expect(missing.confidence == .c)

        #expect(throws: FaultDatasetDecodingError.malformedPayload) {
            _ = try FaultDatasetJSONDecoder().decode(Data("not json".utf8))
        }
        #expect(throws: FaultDatasetDecodingError.unsupportedVersion(2)) {
            _ = try FaultDatasetJSONDecoder().decode(
                Data(#"{"version":2,"source":"x","lines":[]}"#.utf8)
            )
        }
    }

    @Test("Data provider surfaces the decoded dataset")
    func provider() async throws {
        let dataset = try await DataFaultDatasetProvider(data: try fixtureData()).loadDataset()
        #expect(dataset.lines.count == 4)
    }
}

@Suite("Fault map style policy")
struct FaultMapStylePolicyTests {
    @Test("Confidence colors match the web palette")
    func colors() {
        #expect(FaultMapStylePolicy.colorName(for: .a) == "b91c1c")
        #expect(FaultMapStylePolicy.colorName(for: .b) == "ef4444")
        #expect(FaultMapStylePolicy.colorName(for: .c) == "f87171")
        #expect(FaultMapStylePolicy.colorName(for: .d) == "fca5a5")
    }

    @Test("Base weights match the web rate mapping")
    func baseWeights() {
        #expect(FaultMapStylePolicy.baseWeight(for: .one) == 4)
        #expect(FaultMapStylePolicy.baseWeight(for: .two) == 3)
        #expect(FaultMapStylePolicy.baseWeight(for: .three) == 2)
    }

    @Test("Zoom factor clamps between 0.58 and 1.25")
    func zoomFactor() {
        #expect(FaultMapStylePolicy.zoomFactor(for: 5) == 0.58)
        #expect(abs(FaultMapStylePolicy.zoomFactor(for: 10) - 1.03) < 0.000_001)
        #expect(FaultMapStylePolicy.zoomFactor(for: 20) == 1.25)
        #expect(FaultMapStylePolicy.zoomFactor(for: 0) == 0.58)
    }

    @Test("Line width rounds to two decimals like the web")
    func lineWidth() {
        #expect(FaultMapStylePolicy.lineWidth(rate: .one, zoom: 5) == 2.32)
        #expect(FaultMapStylePolicy.lineWidth(rate: .three, zoom: 5) == 1.16)
        #expect(FaultMapStylePolicy.lineWidth(rate: .one, zoom: 12) == 4.84)
    }
}
