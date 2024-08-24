//
//  SharingServiceRepresentedView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/07/2024.
//

import SwiftUI

extension AppKitUtils {

    /// SwiftUI `NSViewRepresentable` for a Sharing Service Picker
    public struct SharingServiceRepresentedView: NSViewRepresentable {
        /// Bool to show the sharing picker
        @Binding var isPresented: Bool
        /// The URL of the document to share
        @Binding var url: URL?
        /// Init the `View`
        public init(isPresented: Binding<Bool>, url: Binding<URL?>) {
            self._isPresented = isPresented
            self._url = url
        }
        /// Make the `View`
        public func makeNSView(context: Context) -> NSView {
            let view = NSView()
            return view
        }
        /// Update the `View`
        public func updateNSView(_ nsView: NSView, context: Context) {
            if isPresented, let url {
                let picker = NSSharingServicePicker(items: [url])
                picker.delegate = context.coordinator
                Task {
                    picker.show(relativeTo: .zero, of: nsView, preferredEdge: .minY)
                    isPresented = false
                }
            }
        }
        /// Make a `coordinator` for the `NSViewRepresentable`
        public func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        // swiftlint:disable:next nesting
        public class Coordinator: NSObject, NSSharingServicePickerDelegate {
            /// The parent
            let parent: SharingServiceRepresentedView
            /// Init the **coordinator**
            init(_ parent: SharingServiceRepresentedView) {
                self.parent = parent
            }

            // MARK: Protocol Stuff

            /// Asks your delegate to provide an object that the selected sharing service can use as its delegate
            public func sharingServicePicker(
                _ sharingServicePicker: NSSharingServicePicker,
                sharingServicesForItems items: [Any],
                proposedSharingServices proposedServices: [NSSharingService]
            ) -> [NSSharingService] {
                var share = proposedServices
                /// Add a **print** service to the share-menu
                if
                    let url = parent.url,
                    let image = NSImage(systemSymbolName: "printer", accessibilityDescription: "Printer") {
                    let printService = NSSharingService(title: "Print PDF", image: image, alternateImage: image) {
                        Task {
                            await AppKitUtils.printDialog(exportURL: url)
                        }
                    }
                    share.insert(printService, at: 0)
                }
                return share
            }
            /// Tells the delegate that the person selected a sharing service for the current item
            public func sharingServicePicker(
                _ sharingServicePicker: NSSharingServicePicker,
                didChoose service: NSSharingService?
            ) {
                /// Cleanup
                sharingServicePicker.delegate = nil
            }
        }
    }
}
