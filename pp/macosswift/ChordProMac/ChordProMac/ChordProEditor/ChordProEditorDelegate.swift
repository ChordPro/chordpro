//
//  ChordProEditorDelegate.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/06/2024.
//

import Foundation

/// The delegate for the ``ChordProEditor``
protocol ChordProEditorDelegate: AnyObject {

    /// A delegate function to update a view
    @MainActor func selectionNeedsDisplay()
}
