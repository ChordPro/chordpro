//
//  CloseWindowModifier.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/10/2024.
//

import SwiftUI

struct CloseWindowModifier: ViewModifier {

    /// The action when the close button is pressed
    let action: () -> Void

    @State private var hoverWindow = false
    @State private var hoverButton = false

    /// The body of the `Modifier`
    func body(content: Content) -> some View {
        content
            .cornerRadius(12)
            .onHover { hovering in
                hoverWindow = hovering
            }
            .overlay(alignment: .topLeading) {
                Button {
                    action()
                } label: {
                    Image(systemName: hoverButton ? "xmark.circle.fill" : "xmark.circle")
                        .imageScale(.medium)
                        .foregroundStyle(hoverButton ? .primary : .secondary)
                        .padding(5)
                }
                .keyboardShortcut("w")
                .onHover { hovering in
                    hoverButton = hovering
                }
                .buttonStyle(.plain)
                .opacity(hoverWindow || hoverButton ? 1 : 0)
                .padding(4)
                .animation(.default, value: hoverWindow)
                .animation(.default, value: hoverButton)
            }
    }
}

extension View {

    /// Shortcut to the `WrapSettingsSection` modifier
    /// - Parameter title: The title
    /// - Returns: A modified `View`
    func closeWindowModifier(action: @escaping () -> Void) -> some View {
        modifier(CloseWindowModifier(action: action))
    }
}
