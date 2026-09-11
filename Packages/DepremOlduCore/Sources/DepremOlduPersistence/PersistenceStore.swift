import Foundation

public protocol PersistenceStore: Sendable {
    func data(forKey key: String) async throws -> Data?
    func set(_ data: Data?, forKey key: String) async throws
}
