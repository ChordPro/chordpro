//
//  AppKitUtils+printDialog.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/06/2024.
//

import AppKit
import PDFKit

extension AppKitUtils {

    /// Show a `AppKit` *Print Dialog* for a PDF
    /// - Parameter exportURL: The URL of the export PDF
    @MainActor static func printDialog(exportURL: URL) {
        if let window = NSApp.keyWindow {
            /// Set the print info
            let printInfo = NSPrintInfo()
            /// Build the PDF View
            let pdfView = PDFView()
            pdfView.document = PDFDocument(url: exportURL)
            pdfView.minScaleFactor = 0.1
            pdfView.maxScaleFactor = 5
            pdfView.autoScales = true
            /// Attach the PDF View to the Window
            window.contentView?.addSubview(pdfView)
            /// Show the sheet
            pdfView.print(with: printInfo, autoRotate: false)
            /// Remove the sheet
            pdfView.removeFromSuperview()
        }
    }
}
