//
//  UserFileBookmark.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/06/2024.
//

import SwiftUI
import OSLog
import UniformTypeIdentifiers

/// Persistent user file bookmark utilities
enum UserFileBookmark {
    // Just a placeholder
}

extension UserFileBookmark {

    /// Get an optional bookmark URL
    /// - Parameter bookmark: The ``UserFile``
    /// - Returns: An URL if found
    static func getBookmarkURL<T: UserFile>(_ bookmark: T) -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmark.id) else {
            return nil
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
            return nil
        }
    }
}

extension UserFileBookmark {

    /// Set an bookmark URL
    /// - Parameters:
    ///   - bookmark: The ``UserFile``
    ///   - selectedURL: The URL to set
    static func setBookmarkURL<T: UserFile>(_ bookmark: T, _ selectedURL: URL) {
        do {
            _ = selectedURL.startAccessingSecurityScopedResource()
            let bookmarkData = try selectedURL.bookmarkData(
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: bookmark.id)
            selectedURL.stopAccessingSecurityScopedResource()
            Logger.fileAccess.info("Bookmark set for '\(selectedURL.lastPathComponent, privacy: .public)'")
        } catch let error {
            Logger.fileAccess.error("Bookmark error: '\(error.localizedDescription, privacy: .public)'")
            selectedURL.stopAccessingSecurityScopedResource()
        }
    }
}

extension UserFileBookmark {

    /// Stop access to a persistent URL after some time
    /// - Parameter persistentURL: The `URL` that has accessed
    /// - Note: Always call this function after you are done with the access or else Apple will be really upset!
    static func stopCustomFileAccess(persistentURL: URL) {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000_000)
            persistentURL.stopAccessingSecurityScopedResource()
            Logger.fileAccess.info("Stopped access to '\(persistentURL.lastPathComponent, privacy: .public)'")
        }
    }
}

extension UserFileBookmark {

    /// Open an URL in the Finder
    /// - Parameter url: The URL to open
    static func openInFinder(url: URL?) {
        guard let url = url else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

extension URL {

    /// Open an URL in the Finder
    func openInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([self])
    }
}

extension URL {

    /// Check if an URL exists
    /// - Returns: True of false
    func exist() -> Bool {
        if #available(macOS 13.0, *) {
            return FileManager.default.fileExists(atPath: self.path(percentEncoded: false))
        } else {
            return FileManager.default.fileExists(atPath: self.path)
        }
    }
}
