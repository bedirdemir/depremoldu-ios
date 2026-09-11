import Foundation
import DepremOlduPersistence
import Testing

@Suite("File persistence store")
struct FilePersistenceStoreTests {
    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("depremoldu-persistence-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("Write, read and delete round-trip")
    func roundTrip() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try FilePersistenceStore(directoryURL: directory)
        #expect(try await store.data(forKey: "missing") == nil)

        let payload = Data("payload".utf8)
        try await store.set(payload, forKey: "feed:v1")
        #expect(try await store.data(forKey: "feed:v1") == payload)

        try await store.set(nil, forKey: "feed:v1")
        #expect(try await store.data(forKey: "feed:v1") == nil)
    }

    @Test("Overwrite replaces the previous record atomically")
    func overwrite() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try FilePersistenceStore(directoryURL: directory)
        try await store.set(Data("first".utf8), forKey: "key")
        try await store.set(Data("second".utf8), forKey: "key")
        #expect(try await store.data(forKey: "key") == Data("second".utf8))
    }

    @Test("Keys are SHA-256 filenames and traversal-safe")
    func fileNamePolicy() {
        let name = FilePersistenceStore.fileName(forKey: "../../etc/passwd")
        #expect(!name.contains("/"))
        #expect(!name.contains(".."))
        #expect(name.hasSuffix(".cache"))
        #expect(name.count == 70)
        #expect(FilePersistenceStore.fileName(forKey: "same") == FilePersistenceStore.fileName(forKey: "same"))
        #expect(FilePersistenceStore.fileName(forKey: "a") != FilePersistenceStore.fileName(forKey: "b"))
    }

    @Test("Directory creation failure is a typed error")
    func directoryFailure() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("depremoldu-not-a-directory-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: fileURL) }

        #expect(throws: FilePersistenceStoreError.unableToCreateDirectory) {
            _ = try FilePersistenceStore(directoryURL: fileURL)
        }
    }
}
