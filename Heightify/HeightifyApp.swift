//
//  HeightifyApp.swift
//  Heightify
//
//  Created by Soleil Yu on 2025/2/15.
//

import SwiftUI

@main
struct HeightifyApp: App {
    @StateObject private var languageSettings = LanguageSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageSettings)
        }
    }
}
