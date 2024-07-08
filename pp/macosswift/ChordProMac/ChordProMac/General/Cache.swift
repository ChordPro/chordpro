//
//  Cache.swift
//  Chord Provider
//
//  © 2024 Nick Berendsen
//

import Foundation

/// Get and set structs to the cache directory
/// - Note: This is used to get and save the application settings
public enum Cache {

    /// Get a struct from the cache
    /// - Parameters:
    ///   - key: The name of the item in the cache
    ///   - struct: The struct to use for decoding
    /// - Returns: decoded cache item
    public static func get<T: Codable>(key: String, struct: T.Type) throws -> T {
        let file = try self.path(for: key)
        let data = try Data(contentsOf: file)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Save a struct into the cache
    /// - Parameters:
    ///   - key: The name for the item in the cache
    ///   - object:The struct to save
    /// - Throws: an error if it can't be saved
    public static func set<T: Codable>(key: String, object: T) throws {
        let file = try self.path(for: key)
        let archivedValue = try JSONEncoder().encode(object)
        try archivedValue.write(to: file)
    }

    /// Delete a struct from the cache
    /// - Parameters:
    ///   - key: The name for the item in the cache
    /// - Throws: an error if it can't be saved
    public static func delete(key: String) throws {
        let file = try self.path(for: key)
        try FileManager.default.removeItem(atPath: file.path)
    }

    /// Get the path to the cache directory
    /// - Parameters:
    ///   - key: The name of the cache item
    /// - Returns: A full ``URL`` to the cache directory
    private static func path(for key: String) throws -> URL {
        let manager = FileManager.default
        let rootFolderURL = manager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        let nestedFolderURL = rootFolderURL[0]
        return nestedFolderURL.appendingPathComponent(key + ".cache")
    }
}
