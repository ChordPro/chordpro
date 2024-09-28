//
//  ChordProEditor+Internals.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/06/2024.
//

import Foundation

extension ChordProEditor {

    /// Share internal editor stuff with the SwiftUI `View`
    struct Internals: Sendable {
        /// The optional directive in the current paragraph
        var directive: ChordProDirective?
        /// The optional directive argument in the current paragraph
        var directiveArgument: String = ""
        /// The range of the optional detection
        var directiveRange: NSRange?
        /// Bool if the directive is double-clicked
        var clickedDirective: Bool = false
        /// The currently selected range
        var selectedRange = NSRange()
        /// The ``textView``
        var textView: TextView?
    }
}
