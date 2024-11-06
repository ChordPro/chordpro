//
//  ChordProEditor+Coordinator.swift
//  ChordProMac
//

import SwiftUI

extension ChordProEditor {

    // MARK: The coordinator for the editor

    /// The coordinator for the ``ChordProEditor``
    class Coordinator: NSObject, NSTextViewDelegate {
        /// The parent
        var parent: ChordProEditor
        /// The optional balance string, close  a`{` or `[`
        private var balance: String?
        /// Bool if the whole text must be (re)highlighted or just the current fragment
        private var fullHighlight: Bool = true
        /// Debounce task for the text update
        var task: Task<Void, Never>?

        /// Init the **coordinator**
        /// - Parameter parent: The ``ChordProEditor``
        init(_ parent: ChordProEditor) {
            self.parent = parent
        }

        // MARK: Protocol Functions

        func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            /// Rewrite context-menu, the original is full with useless rubbish...
            guard let textView = view as? TextView else {
                return menu
            }
            let newMenu = NSMenu()
            newMenu.allowsContextMenuPlugIns = false
            newMenu.autoenablesItems = false
            newMenu.addItem(
                withTitle: "Cut",
                action: #selector(NSText.cut(_:)),
                keyEquivalent: ""
            ).isEnabled = textView.selectedRange().length != 0
            newMenu.addItem(
                withTitle: "Copy",
                action: #selector(NSText.copy(_:)),
                keyEquivalent: ""
            ).isEnabled = textView.selectedRange().length != 0
            newMenu.addItem(
                withTitle: "Paste",
                action: #selector(NSText.paste(_:)),
                keyEquivalent: ""
            ).isEnabled = (NSPasteboard.general.string(forType: .string) != nil)
            newMenu.addItem(
                withTitle: "Select All",
                action: #selector(NSText.selectAll(_:)),
                keyEquivalent: ""
            )
            return newMenu
        }

        /// Protocol function to check if a text should change
        /// - Parameters:
        ///   - textView: The `NSTextView`
        ///   - affectedCharRange: The character range that is affected
        ///   - replacementString: The optional replacement string
        /// - Returns: True or false
        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            balance = replacementString == "[" ? "]" : replacementString == "{" ? "}" : nil
            fullHighlight = replacementString?.count ?? 0 > 1
            return true
        }

        /// Protocol function with a notification that the text has changed
        /// - Parameter notification: The notification with the `NSTextView` as object
        func textDidChange(_ notification: Notification) {
            guard
                let textView = notification.object as? TextView,
                let range = textView.selectedRanges.first?.rangeValue
            else {
                return
            }
            /// Check if a typed `[` or `{` should be closed
            if let balance {
                textView.insertText(balance, replacementRange: range)
                textView.selectedRanges = [NSValue(range: range)]
                self.balance = nil
            }
            let composeText = textView.string as NSString
            var highlightRange = NSRange()
            if fullHighlight {
                /// Full highlighting of the document
                highlightRange = NSRange(location: 0, length: composeText.length)
            } else {
                /// Highlight only the current paragraph
                highlightRange = composeText.paragraphRange(for: textView.selectedRange)
            }
            /// Do the highlighting
            parent.highlightText(textView: textView, range: highlightRange)
            /// Update the fragment information
            textView.setFragmentInformation(selectedRange: range)
            /// Debounce the text update
            self.task?.cancel()
            self.task = Task {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    parent.text = textView.string
                    /// Remove the task so we allow external updates of the text binding again
                    self.task = nil
                } catch { }
            }
        }

        /// Protocol function with a notification that the text selection has changed
        /// - Parameter notification: The notification with the `NSTextView` as object
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? TextView, let range = textView.selectedRanges.first?.rangeValue
            else { return }
            /// Update the fragment information
            textView.setFragmentInformation(selectedRange: range)
            textView.chordProEditorDelegate?.selectionNeedsDisplay()
        }
    }
}
