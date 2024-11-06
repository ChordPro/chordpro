//
//  SongbookStateModel.swift
//  ChordProMac
//

import AppKit
import OSLog

/// The observable state of the songbook
class SongbookStateModel: ObservableObject {
    /// The songbook as PDF
    @Published var pdf: Data?
    /// Bool to present an export dialog
    @Published  var exportFolderDialog = false
    /// Bool if **ChordPro** is making the songbook
    @Published var chordProRunning: Bool = false
    /// Optional URL to show the custom cover in Quickview
    @Published var coverPreview: URL?
    /// Bool if the dropping is in progress
    @Published var isDropping = false
    /// The current selected folder
    @Published var currentFolder: String? = SongbookStateModel.exportFolderTitle
    /// The current selected cover
    @Published var currentCover: String? = SongbookStateModel.exportCoverTitle
    /// Bool to present the import songlist dialog
    @Published var importSonglistDialog: Bool = false
    /// Bool to present the export songlist dialog
    @Published var exportSonglistDialog: Bool = false
}

extension SongbookStateModel {

    /// Get the label for a song count
    func songCountLabel(count: Int) -> String {
        let folder = UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder)
        switch count {
        case 0:
            return folder == nil ? "Select a folder with your **ChordPro** songs" : "There are no songs in this folder"
        default:
            return "Found \(count) **ChordPro** songs in this folder"
        }
    }

    // MARK: Make a list of songs from a file

    /// Make a list of songs from a selected file
    /// - Parameters:
    ///   - fileURL: The URL of the selected file
    ///   - appState: The state of the application with the songbook settings
    @MainActor func makeFileListFromFile(fileURL: URL, appState: AppStateModel, sceneState: SceneStateModel) {
        do {
            let data = try String(contentsOf: fileURL, encoding: .utf8)
            var fileList: [FileListItem] = []
            var status: AppError = .noErrorOccurred
            for file in data.components(separatedBy: .newlines) where !file.isEmpty {
                let url = URL(fileURLWithPath: file)
                if url.exist() {
                    fileList.append(
                        FileListItem(
                            url: url,
                            path: url.deletingLastPathComponent().path.split(separator: "/").map(String.init),
                            enabled: true
                        )
                    )
                } else {
                    status = .songbookListMissingItems
                    sceneState.logMessages.append(.init(type: .error, message: "'\(file)' not found"))
                }
            }
            appState.settings.application.fileList = fileList
            sceneState.exportStatus = status
        } catch {
            Logger.fileAccess.error("\(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: Make a list of songs from a folder

    /// Make a list of songs from the selected folder
    /// - Parameter appState: The state of the application with the songbook settings
    @MainActor func makeFileListFromFolder(appState: AppStateModel) {
        var fileList: [FileListItem] = []

        let enumeratorOptions: FileManager.DirectoryEnumerationOptions = appState.settings.application.recursiveFileList ? [] : [.skipsSubdirectoryDescendants]

        if let songsFolder = UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder) {
            /// Get access to the URL
            _ = songsFolder.startAccessingSecurityScopedResource()
            if
                let items = FileManager.default.enumerator(
                    at: songsFolder,
                    includingPropertiesForKeys: nil,
                    options: enumeratorOptions
                ) {
                while let item = items.nextObject() as? URL {
                    if ChordProDocument.fileExtension.contains(item.pathExtension) {
                        if let existingSong = appState.settings.application.fileList.first(where: {$0.url == item }) {
                            fileList.append(existingSong)
                        } else {
                            /// Remove the base path from the song path
                            let path = item.deletingLastPathComponent().path.replacingOccurrences(
                                of: UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder)?.path ?? "",
                                with: ""
                            )
                            fileList.append(
                                FileListItem(
                                    url: item,
                                    path: path.split(separator: "/").map(String.init),
                                    enabled: true
                                )
                            )
                        }
                    }
                }
            }
            /// Close access to the URL
            songsFolder.stopAccessingSecurityScopedResource()
        }
        fileList.sort {$0.url.path < $1.url.path}
        appState.settings.application.fileList = fileList
    }

    func getSongsPathList(
        appState: AppStateModel
    ) -> [String] {
        /// Start with a fresh list
        var songsPath: [String] = []
        /// Collect the songs that are enabled
        if let songsFolder = UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder) {
            /// Get access to the URL
            _ = songsFolder.startAccessingSecurityScopedResource()
            songsPath = appState.settings.application.fileList.filter {$0.enabled == true}.map(\.url.path)
            /// Close access to the URL
            songsFolder.stopAccessingSecurityScopedResource()
        }
        return songsPath
    }

    // MARK: Make a Songbook

    /// Make a **ChordPro** songbook with the list of songs
    /// - Parameters:
    ///   - appState: The state of the application with the songbook settings
    ///   - sceneState: The state of the scene
    @MainActor func makeSongbook(
        appState: AppStateModel,
        sceneState: SceneStateModel
    ) {
        chordProRunning = true
        /// Get the list with songs that are enabled in the current list
        let songsPath = getSongsPathList(appState: appState)
        /// Write it to the file list
        do {
            try songsPath
                .joined(separator: "\n")
                .write(to: sceneState.fileListURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            Logger.fileAccess.error("Could not write the file list")
        }
        Task {
            do {
                /// Create the PDF with **ChordPro**
                let pdf = try await sceneState.exportToPDF(
                    text: "",
                    fileList: true,
                    title: appState.settings.application.songbookTitle,
                    subtitle: appState.settings.application.songbookSubtitle
                )
                /// Set the PDF as Data
                self.pdf = pdf.data
            } catch {
                Logger.pdfBuild.error("\(error.localizedDescription, privacy: .public)")
            }
            chordProRunning = false
        }
    }

    /// Open a song window with an URL
    /// - Parameter url: The URL of the song
    @MainActor func openSong(url: URL) async {
        if let persistentURL = UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder) {
            _ = persistentURL.startAccessingSecurityScopedResource()
            do {
                try await NSDocumentController.shared.openDocument(withContentsOf: url, display: true)
            } catch {
                Logger.application.error("Error opening URL: \(error.localizedDescription, privacy: .public)")
            }
            persistentURL.stopAccessingSecurityScopedResource()
        }
    }
}

extension SongbookStateModel {
    /// Get the title of the current selected export folder
    static var exportFolderTitle: String? {
        UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder)?.lastPathComponent
    }
    /// Get the current selected export cover
    static var exportCoverTitle: String? {
        UserFileBookmark.getBookmarkURL(UserFileItem.songbookCover)?.lastPathComponent
    }
}
