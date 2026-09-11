import CryptoKit
import Foundation

public enum FilePersistenceStoreError: Error, Equatable, Sendable {
    case unableToCreateDirectory
    case unableToRead
    case unableToWrite
    case unableToDelete
}

public actor FilePersistenceStore: PersistenceStore {
    private let directoryURL: URL

    public init(directoryURL: URL) throws {
        self.directoryURL = directoryURL
        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw FilePersistenceStoreError.unableToCreateDirectory
        }
    }

    public func data(forKey key: String) async throws -> Data? {
        let url = fileURL(forKey: key)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw FilePersistenceStoreError.unableToRead
        }
    }

    public func set(_ data: Data?, forKey key: String) async throws {
        let url = fileURL(forKey: key)

        guard let data else {
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                throw FilePersistenceStoreError.unableToDelete
            }
            return
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw FilePersistenceStoreError.unableToWrite
        }
    }

    public static func fileName(forKey key: String) -> String {
        SHA256.hash(data: Data(key.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
            .appending(".cache")
    }

    private func fileURL(forKey key: String) -> URL {
        directoryURL.appendingPathComponent(Self.fileName(forKey: key), isDirectory: false)
    }
}
