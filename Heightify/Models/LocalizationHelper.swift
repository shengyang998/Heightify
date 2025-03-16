import SwiftUI

// Extension to make localization easier to use in SwiftUI
extension String {
    func localized(using languageSettings: LanguageSettings) -> String {
        return languageSettings.localized(self)
    }
}

// Extension to Text for easier localization
extension Text {
    static func localized(_ key: String, languageSettings: LanguageSettings) -> Text {
        return Text(languageSettings.localized(key))
    }
}

// View modifier for localized text
struct LocalizedText: ViewModifier {
    let key: String
    @EnvironmentObject var languageSettings: LanguageSettings
    
    func body(content: Content) -> some View {
        Text(languageSettings.localized(key))
    }
}

extension View {
    func localizedText(_ key: String) -> some View {
        modifier(LocalizedText(key: key))
    }
} 