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
        url
    }
    /// The `URL` of the template
    let url: URL
    /// The calculated label of the template
    var label: String {
        let label = self.url.deletingPathExtension()
        return label.lastPathComponent
    }
}
