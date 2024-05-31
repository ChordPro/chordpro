//
//  Cache.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import Foundation

/// Get and set structs to the cache directory
public enum Cache {

    /// Get a struct from the cache
    /// - Parameters:
    ///   - key: The name of the item in the cache
    ///   - as: The struct to use for decoding
    ///   - folder: The optional subfolder to store the item
    /// - Returns: decoded cache item
    public static func get<T: Codable>(key: String, as: T.Type, folder: String? = nil) throws -> T {
        let file = try self.path(for: key, folder: folder)
        let data = try Data(contentsOf: file)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Save a struct into the cache
    /// - Parameters:
    ///   - key: The name for the item in the cache
    ///   - object:Tthe struct to save
    ///   - folder: The optional subfolder to store the item
    /// - Throws: an error if it can't be saved
    public static func set<T: Codable>(key: String, object: T, folder: String? = nil) throws {
        let file = try self.path(for: key, folder: folder)
        let archivedValue = try JSONEncoder().encode(object)
        try archivedValue.write(to: file)
    }

    /// Delete a struct from the cache
    /// - Parameters:
    ///   - key: The name for the item in the cache
    ///   - folder: The optional subfolder to store the item
    /// - Throws: an error if it can't be saved
    public static func delete(key: String, folder: String? = nil) throws {
        let file = try self.path(for: key, folder: folder)
        try FileManager.default.removeItem(atPath: file.path)
    }

    /// Get the path to the cache directory
    /// - Parameters:
    ///   - key: The name of the cache item
    ///   - folder: The optional subfolder to store the item
    /// - Returns: A full ``URL`` to the cache direcory
    static private func path(for key: String, folder: String?) throws -> URL {
        let manager = FileManager.default
        let rootFolderURL = manager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        var nestedFolderURL = rootFolderURL[0]
        /// Add the optional subfolder
        if let folder {
            nestedFolderURL = rootFolderURL[0].appendingPathComponent(folder)
            if !manager.fileExists(atPath: nestedFolderURL.relativePath) {
                try manager.createDirectory(
                    at: nestedFolderURL,
                    withIntermediateDirectories: false,
                    attributes: nil
                )
            }
        }
        return nestedFolderURL.appendingPathComponent(key + ".cache")
    }
}
