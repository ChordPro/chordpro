//
//  Template.swift
//  ChordProMac
//

import Foundation

/// A template we found in the **ChordPro** source
struct Template: Identifiable, Codable, Equatable {
    /// The calculated ID of the template
    var id: URL {
        return url
    }
    /// The `URL` of the template
    let url: URL
    /// Bool if the template is enabled
    var enabled: Bool = false
    /// The file name of the template
    var fileName: String {
        return self.url.deletingPathExtension().lastPathComponent
    }
    /// The calculated label of the template
    var label: String {
        return self.url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
