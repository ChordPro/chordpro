//
//  Template.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import Foundation

/// A template we found in the **ChordPro** source
struct Template: Identifiable {
    /// The calculated ID of the template
    var id: URL {
        return url
    }
    /// The `URL` of the template
    let url: URL
    /// The file name of the template
    var fileName: String {
        return self.url.deletingPathExtension().lastPathComponent
    }
    /// The calculated label of the template
    var label: String {
        return self.url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
