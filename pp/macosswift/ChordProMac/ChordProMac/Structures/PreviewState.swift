//
//  PreviewState.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 02/07/2024.
//

import Foundation

/// The state of a PDF preview
struct PreviewState: Equatable {
    /// The optional data for a preview
    var data: Data?
    /// Bool if the preview is outdated
    var outdated: Bool = false
    /// Bool if the preview is active
    var active: Bool {
        return data != nil
    }
}
