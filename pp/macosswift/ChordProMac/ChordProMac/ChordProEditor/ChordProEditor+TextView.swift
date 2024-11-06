//
//  ChordProEditor+TextView.swift
//  ChordProMac
//

import SwiftUI

extension ChordProEditor {

    // MARK: The text view for the editor

    /// The text view for the editor
    class TextView: NSTextView {
        /// The delegate for the ChordProEditor
        var chordProEditorDelegate: ChordProEditorDelegate?
        /// The parent
        var parent: ChordProEditor?
        /// All the directives we know about
        var directives: [ChordProDirective] = []
        /// The log from the song parser
        var log: [LogItem] = []
        /// The current line number of the cursor
        var currentLineNumber: Int = 0
        /// The optional current directive of the paragraph
        var currentDirective: ChordProDirective?
        /// The optional argument of the current directive
        var currentDirectiveArgument: String = ""
        /// The range of the current directive
        var currentDirectiveRange: NSRange?
        /// The rect of the current paragraph
        var currentParagraphRect: NSRect?
        /// The optional double-clicked directive in the editor
        var clickedDirective: Bool = false
        /// The selected text in the editor
        var selectedText: String {
            if let swiftRange = Range(selectedRange(), in: string) {
                return String(string[swiftRange])
            }
            return ""
        }

        // MARK: Override functions

        /// Draw a background behind the current fragment
        /// - Parameter dirtyRect: The current rect of the editor
        override func draw(_ dirtyRect: CGRect) {
            guard let context = NSGraphicsContext.current?.cgContext else { return }
            /// Highlight the current selected paragraph
            if let currentParagraphRect {
                let lineRect = NSRect(
                    x: 0,
                    y: currentParagraphRect.origin.y,
                    width: dirtyRect.width,
                    height: currentParagraphRect.height
                )
                context.setFillColor(ChordProEditor.highlightedForegroundColor.cgColor)
                context.fill(lineRect)
            }
            super.draw(dirtyRect)
        }

        /// Handle double-click on directives to edit them
        /// - Parameter event: The mouse click event
        override func mouseDown(with event: NSEvent) {
            setFragmentInformation(selectedRange: selectedRange())
            if event.clickCount == 2, let currentDirective, currentDirective.editable == true {
                clickedDirective = true
                parent?.runIntrospect(self)
            } else {
                clickedDirective = false
                return super.mouseDown(with: event)
            }
        }

        /// Set the selection to the characters in an array of ranges in response to user action
        override func setSelectedRange(
            _ charRange: NSRange,
            affinity: NSSelectionAffinity,
            stillSelecting stillSelectingFlag: Bool
        ) {
            super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
            needsDisplay = true
            chordProEditorDelegate?.selectionNeedsDisplay()
        }

        // MARK: Custom functions

        /// Replace the whole text with a new text
        /// - Parameter text: The replacement text
        func replaceText(text: String) {
            let composeText = self.string as NSString
            self.insertText(text, replacementRange: NSRange(location: 0, length: composeText.length))
        }

        /// Set the fragment information
        /// - Parameter selectedRange: The current selected range of the text editor
        func setFragmentInformation(selectedRange: NSRange) {
            guard
                let textStorage = textStorage,
                let textContainer = textContainer,
                let layoutManager = layoutManager as? LayoutManager
            else {
                return
            }
            let composeText = textStorage.string as NSString
            let nsRange = composeText.paragraphRange(for: selectedRange)
            /// Set the rect of the current paragraph
            currentParagraphRect = layoutManager.boundingRect(forGlyphRange: nsRange, in: textContainer)
            /// Reduce the height of the rect if we have an extra line fragment and are on the last line with content
            if
                layoutManager.extraLineFragmentTextContainer != nil,
                NSMaxRange(nsRange) == composeText.length,
                nsRange.length != 0 {
                currentParagraphRect?.size.height -= layoutManager.lineHeight
            }
            /// Find the optional directive of the fragment
            var directive: ChordProDirective?
            textStorage.enumerateAttribute(.directive, in: nsRange) {values, _, _ in
                if let value = values as? String, directives.map(\.directive).contains(value) {
                    directive = directives.first { $0.directive == value }
                }
            }
            /// Find the optional directive argument of the fragment
            var directiveArgument: String?
            textStorage.enumerateAttribute(.directiveArgument, in: nsRange) {values, _, _ in
                if let value = values as? String {
                    directiveArgument = value
                }
            }
            /// Get the range of the directive for optional editing
            var directiveRange: NSRange?
            if currentDirective != nil {
                textStorage.enumerateAttribute(.directiveRange, in: nsRange) {values, _, _ in
                    if let value = values as? NSRange {
                        directiveRange = value
                    }
                }
            }
            /// Set the found values
            currentDirective = directive
            currentDirectiveArgument = directiveArgument?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            currentDirectiveRange = directiveRange
            /// Run introspect to inform the SwiftUI `View`
            parent?.runIntrospect(self)
        }
    }
}
