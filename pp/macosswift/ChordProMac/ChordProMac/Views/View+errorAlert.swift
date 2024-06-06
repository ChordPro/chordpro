//
//  View+errorAlert.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 02/06/2024.
//

import SwiftUI

extension View {

    /// Show a SwiftUI `Alert` with an `Error` message
    /// - Parameters:
    ///   - error: Binding to the `Error` to show
    ///   - log: Binging to the bool to show te log
    /// - Returns: A SwiftUI `Alert`
    func errorAlert(error: Binding<Error?>, log: Binding<Bool>) -> some View {
        /// Wrap the `Error` in a ``LocalizedAlertError``
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        /// Return the `Alert`
        return alert(
            isPresented: .constant(localizedAlertError != nil),
            error: localizedAlertError
        ) { _ in
            Button("OK") {
                error.wrappedValue = nil
            }
            Button("Show Log") {
                error.wrappedValue = nil
                log.wrappedValue = true
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}
