//
//  AppKitUtils+openPanel.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/06/2024.
//

import AppKit
import UniformTypeIdentifiers
import OSLog

extension AppKitUtils {

    /// Show an `AppKit` *NSOpenPanel*
    ///
    /// I don't use the `SwiftUI` `.fileImporter` here because it is too limited;
    /// especially on macOS versions lower than 14.
    /// So, I just call a good o'l NSOpenPanel here.`
    ///
    /// - Parameters:
    ///   - userFile: The ``UserFile`` to open
    ///   - action: The action when a file is selected
    @MainActor static func openPanel<T: UserFile>(userFile: T, action: @escaping () -> Void) throws {
        /// Make sure we have a window to attach the sheet
        guard let window = NSApp.keyWindow else {
            throw CocoaError(.featureUnsupported)
        }
        let lastSelectedURL = UserFileBookmark.getBookmarkURL(userFile)
        let openPanel = NSOpenPanel()
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = userFile.utTypes.contains(UTType.folder) ? true : false
        openPanel.allowedContentTypes = userFile.utTypes
        openPanel.directoryURL = lastSelectedURL
        openPanel.message = userFile.message
        openPanel.prompt = "Select"
        openPanel.canCreateDirectories = false
        /// Open the panel in a sheet
        openPanel.beginSheetModal(for: window) { result in
            guard  result == .OK, let url = openPanel.url else {
                return
            }
            UserFileBookmark.setBookmarkURL(userFile, url)
            Logger.application.info("Bookmark set for '\(url.lastPathComponent, privacy: .public)'")
            action()
        }
    }
}
