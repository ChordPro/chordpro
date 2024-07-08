//
//  ColorPickerButtonView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/06/2024.
//

import SwiftUI

/// SwiftUI `View` with a `Button` to select a `Color`
public struct ColorPickerButtonView: View {
    /// Binding to the selected color
    @Binding var selectedColor: Color
    /// The label that goes in front of the button
    let label: String
    /// Bool to show the popup
    @State private var showPopup: Bool = false
    /// All the available dynamic colors
    private let dynamicColors: [Color] = [
        .primary,
        .secondary,
        .accentColor
    ]
    /// All the available system colors
    private let systemColors: [Color] = [
        .black,
        .blue,
        .brown,
        .cyan,
        .gray,
        .green,
        .indigo,
        .mint,
        .orange,
        .pink,
        .purple,
        .red,
        .teal,
        .white,
        .yellow
    ]
    /// Init the struct
    /// - Parameters:
    ///   - selectedColor: Binding to the selected color
    ///   - label: The label for the color picker
    public init(selectedColor: Binding<Color>, label: String) {
        self._selectedColor = selectedColor
        self.label = label
    }
    /// The body of the `View`
    public var body: some View {
        HStack {
            Text(.init(label))
            Spacer()
            Button {
                showPopup = true
            } label: {
                selectedColor
                    .border(Color(nsColor: .textBackgroundColor), width: 2)
                    .frame(width: 40, height: 20)
                    .shadow(radius: 1)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPopup) {
                ScrollView(.horizontal) {
                    VStack {
                        HStack {
                            ForEach(dynamicColors, id: \.self) { color in
                                label(color: color)
                            }
                        }
                        Divider()
                        HStack {
                            ForEach(systemColors, id: \.self) { color in
                                label(color: color)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    /// The `View` for the label
    private func label(color: Color) -> some View {
        VStack {
            Circle()
                .strokeBorder(Color(nsColor: .textBackgroundColor), lineWidth: 2)
                .background(Circle().fill(color))
                .shadow(radius: 1)
                .onTapGesture {
                    selectedColor = color
                    showPopup = false
                }
                .frame(width: 20, height: 20)
            Text(color == .accentColor ? "accent" : color.description)
                .font(.caption)
        }
    }
}
