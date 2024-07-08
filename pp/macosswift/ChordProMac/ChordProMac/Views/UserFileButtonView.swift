//
//  UserFileButtonView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/06/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

/// SwiftUI `View`to select a file
/// 
/// I don't use the `SwiftUI` '.fileImporter' here because it is too limited;
/// especially on macOS versions lower than 14.
/// So, I just call a good o'l NSOpenPanel here.`
///
/// - Note: A file can be a *normal* file but also a folder
public struct UserFileButtonView<T: UserFile>: View {
    /// Init the struct
    public init(userFile: T, action: @escaping () -> Void) {
        self.userFile = userFile
        self.action = action
    }
    /// The file to bookmark
    let userFile: T
    /// The action when a file is selected
    let action: () -> Void
    /// The label of the button
    @State private var label: String?
    /// The body of the `View`
    public var body: some View {
        Button(
            action: {
                try? AppKitUtils.openPanel(userFile: userFile) {
                    action()
                    label = userFile.label
                }
            },
            label: {
                Label(label ?? "Select", systemImage: userFile.icon)
            }
        )
        .task {
            label = userFile.label
        }
    }
}
