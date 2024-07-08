//
//  ChordProEditor+LayoutManager.swift
//  Chord Provider
//
//  © 2023 Nick Berendsen
//

import AppKit

extension ChordProEditor {

    // MARK: The layout manager for the editor

    /// The layout manager for the editor
    class LayoutManager: NSLayoutManager, NSLayoutManagerDelegate {

        var font: NSFont {
            return self.firstTextView?.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        }

        var fontLineHeight: CGFloat {
            return self.defaultLineHeight(for: font)
        }

        var lineHeight: CGFloat {
            let lineHeight = fontLineHeight * ChordProEditor.lineHeightMultiple
            return lineHeight
        }

        var baselineNudge: CGFloat {
            return (lineHeight - fontLineHeight) * 0.5
        }

        /// Takes care only of the last empty newline in the text backing store, or totally empty text views.
        override func setExtraLineFragmentRect(
            _ fragmentRect: NSRect,
            usedRect: NSRect,
            textContainer container: NSTextContainer
        ) {
            var fragmentRect = fragmentRect
            fragmentRect.size.height = lineHeight
            var usedRect = usedRect
            usedRect.size.height = lineHeight
            /// Call the super function
            super.setExtraLineFragmentRect(
                fragmentRect,
                usedRect: usedRect,
                textContainer: container
            )
        }

        // MARK: Layout Manager Delegate

        // swiftlint:disable:next function_parameter_count
        public func layoutManager(
            _ layoutManager: NSLayoutManager,
            shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>,
            lineFragmentUsedRect: UnsafeMutablePointer<NSRect>,
            baselineOffset: UnsafeMutablePointer<CGFloat>,
            in textContainer: NSTextContainer,
            forGlyphRange glyphRange: NSRange
        ) -> Bool {

            var rect = lineFragmentRect.pointee
            rect.size.height = lineHeight

            var usedRect = lineFragmentUsedRect.pointee
            usedRect.size.height = max(lineHeight, usedRect.size.height)

            lineFragmentRect.pointee = rect
            lineFragmentUsedRect.pointee = usedRect
            baselineOffset.pointee += baselineNudge

            return true
        }
    }
}
