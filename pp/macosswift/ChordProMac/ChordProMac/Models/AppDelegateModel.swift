//
//  AppDelegateModel.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 13/06/2024.
//

import SwiftUI

/// The AppDelegate to bring additional Windows into the SwiftUI world
///
/// - Note: Only from Sonoma, toolbars are supported in a NSHostingView so I just don't use them
class AppDelegateModel: NSObject, NSApplicationDelegate, ObservableObject {

    /// Bool if the application is launched
    var applicationHasLaunched: Bool = false

    /// Close all windows except the menuBarExtra
    /// - Note: Part of the `DocumentGroup` dirty hack; don't show the NSOpenPanel
    func applicationDidFinishLaunching(_ notification: Notification) {
        for window in NSApp.windows where window.styleMask.rawValue != 0 {
            window.close()
        }
        showWelcomeWindow()
    }

    /// Show the ``WelcomeView`` instead of the NSOpenPanel when there are no documents open
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        switch flag {
        case true:
            return true
        case false:
            showWelcomeWindow()
            return false
        }
    }

    /// Don't terminate when the last **ChordPro** window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    /// Default style mask
    let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .titled, .fullSizeContentView]

    // MARK: Welcome View

    /// The controller for the ``WelcomeView``
    private var welcomeWindowController: NSWindowController?
    /// Create and view the ``WelcomeView`` window
    @MainActor func showWelcomeWindow() {
        if welcomeWindowController == nil {
            let window = NSWindow()
            window.styleMask = styleMask
            window.styleMask.remove(.titled)
            window.isMovableByWindowBackground = true
            window.contentView = NSHostingView(rootView: WelcomeView(appDelegate: self))
            window.titlebarAppearsTransparent = true
            window.center()
            /// Just a fancy animation; it is not a document window
            window.animationBehavior = .documentWindow
            welcomeWindowController = NSWindowController(window: window)
        }
        /// Update the recent files list
        AppStateModel.shared.recentFiles = NSDocumentController.shared.recentDocumentURLs
        welcomeWindowController?.showWindow(welcomeWindowController?.window)
        welcomeWindowController?.window?.makeKeyAndOrderFront(self)
    }

    /// Close the newDocumentViewController window
    @MainActor func closeWelcomeWindow() {
        welcomeWindowController?.window?.close()
    }

    // MARK: About View

    /// The controller for the ``AboutView``
    private var aboutWindowController: NSWindowController?
    /// Create and view the ``AboutView``window
    @MainActor func showAboutWindow() {
        if aboutWindowController == nil {
            let window = NSWindow()
            window.styleMask = styleMask
            window.title = "About ChordPro"
            window.contentView = NSHostingView(rootView: AboutView())
            window.center()
            /// Just a fancy animation; it is not a document window
            window.animationBehavior = .documentWindow
            aboutWindowController = NSWindowController(window: window)
        }
        aboutWindowController?.showWindow(aboutWindowController?.window)
    }

    // MARK: Export Songbook View

    /// The controller for the ``ExportSongbookView``
    private var exportSongbookWindowController: NSWindowController?
    /// Create and view the ``ExportSongbookView`` window
    @MainActor func showExportSongbookWindow() {
        if exportSongbookWindowController == nil {
            let window = NSWindow()
            window.styleMask = styleMask
            window.styleMask.update(with: .resizable)
            window.title = "Export a Folder to a Songbook"
            window.contentView = NSHostingView(rootView: ExportSongbookView())
            window.center()
            /// Just a fancy animation; it is not a document window
            window.animationBehavior = .documentWindow
            exportSongbookWindowController = NSWindowController(window: window)
        }
        exportSongbookWindowController?.showWindow(exportSongbookWindowController?.window)
    }
}
