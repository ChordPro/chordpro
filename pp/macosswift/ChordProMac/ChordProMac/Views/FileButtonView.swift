//
//  FileButtonView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View`to select a file
/// - Note: A file can be a *normal* file but also a folder
struct FileButtonView: View {
    /// The file to bookmark
    let bookmark: CustomFile
    /// The action when a file is selected
    let action: () -> Void
    /// Bool to show the file importer sheet
    @State private var isPresented: Bool = false
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                isPresented.toggle()
            },
            label: {
                Label(bookmark.label ?? "Select", systemImage: bookmark.icon)
            }
        )
        .fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [bookmark.utType]
        ) { result in
            switch result {
            case .success(let url):
                FileBookmark.setBookmarkURL(bookmark, url)
                action()
            case .failure(let error):
                Logger.fileAccess.error("\(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
