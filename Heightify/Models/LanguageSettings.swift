import Foundation
import SwiftUI

// Notification name for language changes
extension Notification.Name {
    static let languageChanged = Notification.Name("com.heightify.languageChanged")
}

class LanguageSettings: ObservableObject {
    @Published var currentLanguage: String {
        didSet {
            // Save the language preference
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
            UserDefaults.standard.synchronize()
            
            // Load the strings for the new language
            loadLocalizedStrings()
            
            // Post notification about language change
            NotificationCenter.default.post(name: .languageChanged, object: nil)
            
            // Force refresh the @Published property to trigger view updates
            objectWillChange.send()
        }
    }
    
    // Dictionary to store localized strings
    @Published var localizedStrings: [String: String] = [:]
    
    init() {
        // Get the saved language or use system language as default
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            self.currentLanguage = savedLanguage
        } else {
            // Get system language, default to English if not Chinese
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            self.currentLanguage = preferredLanguage.starts(with: "zh") ? "zh-Hans" : "en"
            UserDefaults.standard.set(self.currentLanguage, forKey: "AppLanguage")
        }
        
        // Load the strings for the initial language
        loadLocalizedStrings()
    }
    
    func switchLanguage() {
        currentLanguage = currentLanguage == "en" ? "zh-Hans" : "en"
    }
    
    var languageIcon: String {
        currentLanguage == "en" ? "🇺🇸" : "🇨🇳"
    }
    
    var languageName: String {
        currentLanguage == "en" ? "English" : "中文"
    }
    
    // Get the next language name (for transition animation)
    var nextLanguageName: String {
        currentLanguage == "en" ? "中文" : "English"
    }
    
    // Get the next language icon (for transition animation)
    var nextLanguageIcon: String {
        currentLanguage == "en" ? "🇨🇳" : "🇺🇸"
    }
    
    // Get a localized string
    func localized(_ key: String) -> String {
        return localizedStrings[key] ?? key
    }
    
    // Load localized strings from the appropriate .strings file
    private func loadLocalizedStrings() {
        // Clear existing strings
        localizedStrings.removeAll()
        
        // Get the path to the .strings file for the current language
        guard let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: currentLanguage) else {
            print("Could not find strings file for language: \(currentLanguage)")
            return
        }
        
        // Load the strings file
        guard let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] else {
            print("Could not load strings file as dictionary")
            return
        }
        
        // Store the strings
        localizedStrings = dictionary
    }
} 