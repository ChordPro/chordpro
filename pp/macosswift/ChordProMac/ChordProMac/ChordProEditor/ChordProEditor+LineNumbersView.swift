//
//  ChordProEditor+LineNumbersView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/06/2024.
//

import AppKit

extension ChordProEditor {

    // MARK: The line numbers view for the editor

    /// The line numbers view for the editor
    class LineNumbersView: NSRulerView {

        // MARK: Override draw

        /// Draw a background a a stroke on the right of the `NSRulerView`
        /// - Parameter dirtyRect: The current rect of the editor
        override func draw(_ dirtyRect: NSRect) {
            guard
                let context: CGContext = NSGraphicsContext.current?.cgContext
            else {
                return
            }
            /// Fill the background
            context.setFillColor(ChordProEditor.highlightedBackgroundColor.cgColor)
            context.fill(bounds)
            /// Draw a border on the right
            context.setStrokeColor(NSColor.secondaryLabelColor.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: bounds.width - 1, y: 0))
            context.addLine(to: CGPoint(x: bounds.width - 1, y: bounds.height))
            context.strokePath()
            /// - Note: Below usually gets called on super.draw(dirtyRect),
            ///         but we're not calling it because that will override the background color
            drawHashMarksAndLabels(in: bounds)
        }

        // MARK: Override drawHashMarksAndLabels

        override func drawHashMarksAndLabels(in rect: NSRect) {
            guard
                let textView: TextView = self.clientView as? TextView,
                let textContainer: NSTextContainer = textView.textContainer,
                let textStorage: NSTextStorage = textView.textStorage,
                let layoutManager: LayoutManager = textView.layoutManager as? LayoutManager,
                let context: CGContext = NSGraphicsContext.current?.cgContext
            else {
                return
            }

            // MARK: Setup variables

            /// Get the current font
            let font: NSFont = layoutManager.font
            /// Set the width of the ruler
            ruleThickness = font.pointSize * 4
            /// The line number
            var lineNumber: Int = 1
            /// Get the range of glyphs in the visible area of the text view
            let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textContainer)
            /// Set the context based on the Y-offset of the text view
            context.translateBy(x: 0, y: convert(NSPoint.zero, from: textView).y)

            // MARK: Set first line number

            /// The line number for the first visible line
            lineNumber += ChordProEditor.newLineRegex.numberOfMatches(
                in: textView.string,
                options: [],
                range: NSRange(location: 0, length: visibleGlyphRange.location)
            )

            // MARK: Draw marks

            /// Go to all paragraphs
            if let visibleSwiftRange = Range(visibleGlyphRange, in: textView.string) {
                textView.string.enumerateSubstrings(
                    in: visibleSwiftRange,
                    options: [.byParagraphs]
                ) { _, substringRange, _, _ in
                    let nsRange = NSRange(substringRange, in: textView.string)
                    let paragraphRect = layoutManager.boundingRect(forGlyphRange: nsRange, in: textContainer)
                    /// Set the marker rect
                    let markerRect = NSRect(
                        x: 0,
                        y: paragraphRect.origin.y,
                        width: rect.width,
                        height: paragraphRect.height
                    )
                    /// Bool if the line should be highlighted
                    let highlight = markerRect.minY == textView.currentParagraphRect?.minY
                    /// Check if the paragraph contains a directive
                    var directive: ChordProDirective?
                    textStorage.enumerateAttribute(.directive, in: nsRange) {values, _, _ in
                        if let value = values as? String, textView.directives.map(\.directive).contains(value) {
                            directive = textView.directives.first { $0.directive == value }
                        }
                    }
                    /// Draw the line number
                    drawLineNumber(
                        lineNumber,
                        inRect: markerRect,
                        highlight: highlight
                    )
                    /// Draw a symbol if we have a known directive
                    if let directive {
                        drawDirectiveIcon(
                            directive,
                            inRect: markerRect,
                            highlight: highlight
                        )
                    }
                    lineNumber += 1
                }
            }
            /// Draw the number of the line
            func drawLineNumber(_ number: Int, inRect rect: NSRect, highlight: Bool) {
                var attributes = ChordProEditor.rulerNumberStyle
                attributes[NSAttributedString.Key.font] = font
                switch highlight {
                case true:
                    context.setFillColor(ChordProEditor.highlightedBackgroundColor.cgColor)
                    context.fill(rect)
                    attributes[NSAttributedString.Key.foregroundColor] = NSColor.textColor
                case false:
                    attributes[NSAttributedString.Key.foregroundColor] = NSColor.secondaryLabelColor
                }
                /// Define the rect of the string
                var stringRect = rect
                /// Move the string a bit up
                stringRect.origin.y -= layoutManager.baselineNudge
                /// And a bit to the left to make space for the optional stmbol
                stringRect.size.width -= font.pointSize * 1.75
                NSString(string: "\(number)").draw(in: stringRect, withAttributes: attributes)
            }
            /// Draw the directive icon of the line
            func drawDirectiveIcon(_ directive: ChordProDirective, inRect rect: NSRect, highlight: Bool) {
                var iconRect = rect
                let imageAttachment = NSTextAttachment()
                let imageConfiguration = NSImage.SymbolConfiguration(pointSize: font.pointSize * 0.7, weight: .medium)
                if let image = NSImage(systemSymbolName: directive.icon, accessibilityDescription: directive.label) {
                    imageAttachment.image = image.withSymbolConfiguration(imageConfiguration)
                    let imageString = NSMutableAttributedString(attachment: imageAttachment)
                    imageString.addAttribute(
                        .foregroundColor,
                        value: highlight ? NSColor.textColor : NSColor.secondaryLabelColor,
                        range: NSRange(location: 0, length: imageString.length)
                    )
                    let imageSize = imageString.size()
                    let offset = (rect.height - imageSize.height) * 0.5
                    iconRect.origin.x += iconRect.width - (imageSize.width * 1.4)
                    iconRect.origin.y += (offset)
                    imageString.draw(in: iconRect)
                }
            }
            /// Get optional directive argument inside the range
            func getDirectiveArgument(nsRange: NSRange) -> String? {
                var string: String?
                textStorage.enumerateAttribute(.directiveArgument, in: nsRange) {values, _, _ in
                    if let value = values as? String {
                        string = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                return string
            }
            textView.parent?.runIntrospect(textView)
        }
    }
}
