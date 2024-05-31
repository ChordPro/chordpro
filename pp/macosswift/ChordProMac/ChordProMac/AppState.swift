//
//  AppState.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import Foundation

/// The observable state of the application
final class AppState: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            try? AppSettings.save(settings: settings)
        }
    }

    /// Init the class; get App settings
    init() {
        self.settings = AppSettings.load()
    }
}
