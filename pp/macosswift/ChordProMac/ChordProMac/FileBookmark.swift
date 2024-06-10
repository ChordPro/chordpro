//
//  FileBookmark.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import SwiftUI
import OSLog

/// Persistent file bookmark utilities
public enum FileBookmark {
    // Just a placeholder
}

extension FileBookmark {

    /// Get an optional bookmark URL
    /// - Parameter bookmark: The ``CustomFile``
    /// - Returns: An URL if found
    static func getBookmarkURL(_ bookmark: CustomFile) throws -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmark.rawValue) else {
            throw AppError.customFileNotFound
        }
        do {
            var bookmarkDataIsStale = false
            let urlForBookmark = try URL(
                resolvingBookmarkData: bookmarkData,
                relativeTo: nil,
                bookmarkDataIsStale: &bookmarkDataIsStale
            )
            if bookmarkDataIsStale {
                setBookmarkURL(bookmark, urlForBookmark)
            }
            return urlForBookmark
        } catch {
            Logger.fileAccess.error("\(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}

extension FileBookmark {

    /// Set an bookmark URL
    /// - Parameters:
    ///   - bookmark: The ``CustomFile``
    ///   - selectedURL: The URL to set
    static func setBookmarkURL(_ bookmark: CustomFile, _ selectedURL: URL) {
        do {
            _ = selectedURL.startAccessingSecurityScopedResource()
            let bookmarkData = try selectedURL.bookmarkData(
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: bookmark.rawValue)
            selectedURL.stopAccessingSecurityScopedResource()
            Logger.fileAccess.info("Bookmark set for '\(selectedURL.lastPathComponent, privacy: .public)'")
        } catch let error {
            Logger.fileAccess.error("Bookmark error: '\(error.localizedDescription, privacy: .public)'")
            selectedURL.stopAccessingSecurityScopedResource()
        }
    }
}

extension FileBookmark {

    /// Stop access to a persistent URL after some time
    /// - Parameter persistentURL: The `URL` that has accessed
    /// - Note: Always call this function after you are done with the access or else Apple will be really upset!
    static func stopCustomFileAccess(persistentURL: URL) {
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            persistentURL.stopAccessingSecurityScopedResource()
            Logger.fileAccess.info("Stopped access to '\(persistentURL.lastPathComponent, privacy: .public)'")
        }
    }
}
