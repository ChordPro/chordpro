//
//  ChordProEditor+Internals.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/06/2024.
//

import Foundation

extension ChordProEditor {

    /// Share internal editor stuff with the SwiftUI `View`
    public struct Internals: Sendable {

        public init(
            directive: ChordProDirective? = nil,
            directiveArgument: String = "",
            directiveRange: NSRange? = nil,
            clickedDirective: Bool = false,
            selectedRange: NSRange = NSRange(),
            textView: TextView? = nil
        ) {
            self.directive = directive
            self.directiveArgument = directiveArgument
            self.directiveRange = directiveRange
            self.clickedDirective = clickedDirective
            self.selectedRange = selectedRange
            self.textView = textView
        }
        /// The optional directive in the current paragraph
        public var directive: ChordProDirective?
        /// The optional directive argument in the current paragraph
        public var directiveArgument: String
        /// The range of the optional detection
        public var directiveRange: NSRange?
        /// Bool if the directive is double-clicked
        public var clickedDirective: Bool = false
        /// The currently selected range
        public var selectedRange = NSRange()
        /// The ``textView``
        public var textView: TextView?
    }
}
