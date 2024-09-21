//
//  FileListItem.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 14/09/2024.
//

import Foundation

/// A song as file list item for export to a Songbook
struct FileListItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var url: URL
    var path: [String]
    var enabled: Bool
}
