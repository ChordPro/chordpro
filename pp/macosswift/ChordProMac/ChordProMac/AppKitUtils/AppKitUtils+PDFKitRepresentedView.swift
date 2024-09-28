//
//  PDFKitRepresentedView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/07/2023.
//

import SwiftUI
import PDFKit
import Quartz

extension AppKitUtils {

    /// SwiftUI `NSViewRepresentable` for a PDF View
    struct PDFKitRepresentedView: NSViewRepresentable {
        /// The data of the PDF
        let data: Data
        /// The optional annotations
        @Binding var annotations: [(userName: String, contents: String)]
        /// Make the `View`
        /// - Parameter context: The context
        /// - Returns: The PDFView
        func makeNSView(context: NSViewRepresentableContext<PDFKitRepresentedView>) -> PDFView {
            /// Create a `PDFView` and set its `PDFDocument`.
            let pdfView = PDFView()
            pdfView.document = PDFDocument(data: data)
            /// Auto scale for macOS Ventura and higher
            if #available(macOS 13.0, *) {
                pdfView.autoScales = true
            }
            /// Set 'autoScales' at the next run for macOS Monterey
            /// or else the PDF will scroll all the way to the bottom on init
            Task { @MainActor in
                if #unavailable(macOS 13.0) {
                    pdfView.autoScales = true
                }
                /// Get the optional debug info
                if let firstPage = pdfView.document?.page(at: 0) {
                    /// Clear the annotations
                    annotations = []
                    for annotation in firstPage.annotations {
                        annotations.append((annotation.userName ?? "Error", annotation.contents ?? "Error"))
                    }
                }
            }
            return pdfView
        }
        /// Update the `View`
        /// - Parameters:
        ///   - pdfView: The PDFView
        ///   - context: The context
        func updateNSView(_ pdfView: PDFView, context: NSViewRepresentableContext<PDFKitRepresentedView>) {
            /// Animate the transition
            pdfView.animator().isHidden = true
            /// Make sure we have a document with a page
            guard
                let currentDestination = pdfView.currentDestination,
                let page = currentDestination.page,
                let document = pdfView.document
            else {
                return
            }
            /// Save the view parameters
            let position = PDFParameters(
                pageIndex: document.index(for: page),
                zoom: currentDestination.zoom,
                location: currentDestination.point
            )
            /// Update the document
            pdfView.document = PDFDocument(data: data)
            /// Restore the view parameters
            if let restoredPage = document.page(at: position.pageIndex) {
                let restoredDestination = PDFDestination(page: restoredPage, at: position.location)
                restoredDestination.zoom = position.zoom
                pdfView.go(to: restoredDestination)
            }
            pdfView.animator().isHidden = false
        }
    }
}

extension AppKitUtils.PDFKitRepresentedView {

    /// The view parameters of a PDF
    struct PDFParameters {
        /// The page index
        let pageIndex: Int
        /// The zoom factor
        let zoom: CGFloat
        /// The location on the page
        let location: NSPoint
    }
}
