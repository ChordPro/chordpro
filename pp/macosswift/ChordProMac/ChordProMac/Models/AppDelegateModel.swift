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

    // MARK: Welcome window

    /// The controller for the `Welcome` window
    private var welcomeWindowController: NSWindowController?
    /// Show the ``WelcomeView`` in an AppKit window
    @MainActor func showWelcomeWindow() {
        if welcomeWindowController == nil {
            let welcomeView = WelcomeView(appDelegate: self, windowID: .welcomeView)
                .closeWindowModifier {
                    self.closeWelcomeWindow()
                }
            let window = createWindow(id: .welcomeView)
            window.styleMask.remove(.titled)
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor.clear
            window.contentView = NSHostingView(rootView: welcomeView)
            window.center()
            welcomeWindowController = NSWindowController(window: window)
        }
        /// Update the recent files list
        AppStateModel.shared.recentFiles = NSDocumentController.shared.recentDocumentURLs
        welcomeWindowController?.showWindow(welcomeWindowController?.window)
        welcomeWindowController?.window?.makeKeyAndOrderFront(self)
    }
    /// Close the ``WelcomeView`` window
    @MainActor func closeWelcomeWindow() {
        welcomeWindowController?.window?.close()
    }

    // MARK: About window

    /// The controller for the `About` window
    private var aboutWindowController: NSWindowController?
    /// Show the ``AboutView`` in an AppKit window
    @MainActor func showAboutWindow() {
        if aboutWindowController == nil {
            let window = createWindow(id: .aboutView)
            window.styleMask.remove(.titled)
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor.clear
            window.contentView = NSHostingView(rootView: AboutView(appDelegate: self))
            window.center()
            /// Just a fancy animation; it is not a document window
            window.animationBehavior = .documentWindow
            aboutWindowController = NSWindowController(window: window)
        }
        aboutWindowController?.showWindow(aboutWindowController?.window)
    }
    /// Close the ``AboutView`` window
    @MainActor func closeAboutWindow() {
        aboutWindowController?.window?.close()
    }

    // MARK: Export Songbook window

    /// The controller for the `Export Songbook` window
    private var exportSongbookWindowController: NSWindowController?
    /// Show the ``ExportSongbookView`` in an AppKit window
    @MainActor func showExportSongbookWindow() {
        if exportSongbookWindowController == nil {
            let window = createWindow(id: .exportSongbookView)
            window.styleMask = styleMask
            window.titlebarAppearsTransparent = false
            window.styleMask.update(with: .resizable)
            window.contentView = NSHostingView(rootView: ExportSongbookView())
            window.center()
            /// Just a fancy animation; it is not a document window
            window.animationBehavior = .documentWindow
            exportSongbookWindowController = NSWindowController(window: window)
        }
        exportSongbookWindowController?.showWindow(exportSongbookWindowController?.window)
    }

    // MARK: Create a default NSWindow

    @MainActor private func createWindow(id: WindowID) -> NSWindow {
        let window = MyNSWindow()
        window.title = id.rawValue
        window.styleMask = styleMask
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.identifier = NSUserInterfaceItemIdentifier(id.rawValue)
        /// Just a fancy animation; it is not a document window
        window.animationBehavior = .documentWindow
        return window
    }

    // MARK: App Window ID's

    /// The windows we can open
    enum WindowID: String {
        /// The ``WelcomeView``
        case welcomeView = "ChordPro"
        /// The ``WelcomeView`` in the menu bar
        case menuBarExtra = "MenuBarExtra"
        /// The ``AboutView``
        case aboutView = "About ChordPro"
        /// The ``ExportSongbookView``
        case exportSongbookView = "Export Songs"
    }
}

extension AppDelegateModel {

    /// Make a NSWindow that can be kay and main
    /// - Note:Needed for Windows that that don't have the `.titled` style mask
    class MyNSWindow: NSWindow {
        /// The window can become main
        override var canBecomeMain: Bool { true }
        /// The window can become key
        override var canBecomeKey: Bool { true }
        /// The window accepts first responder
        override var acceptsFirstResponder: Bool { true }
    }
}
