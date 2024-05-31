//
//  Template.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import Foundation

/// A template we found in the official **ChordPro** source
struct Template: Identifiable {
    var id: URL {
        url
    }
    let url: URL
    var label: String {
        let label = self.url.deletingPathExtension()
        return label.lastPathComponent
    }
}
