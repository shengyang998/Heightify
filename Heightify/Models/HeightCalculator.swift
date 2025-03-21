import Foundation
import SwiftUI

class HeightCalculator {
    /// Represents furniture measurement results in centimeters
    struct FurnitureHeights {
        let chairHeight: Double
        let deskHeight: Double
        
        func description(using languageSettings: LanguageSettings) -> String {
            let template = "Recommended heights:\n- Chair height: %.1f cm\n- Desk height: %.1f cm"
            return String(format: template.localized(using: languageSettings), chairHeight, deskHeight)
        }
    }
    
    /// Calculate optimal furniture heights based on person's height
    /// - Parameter personHeight: Height of the person in centimeters
    /// - Returns: FurnitureHeights containing recommended chair and desk heights
    static func calculateOptimalHeights(personHeight: Double) -> FurnitureHeights {
        // Calculate calf length (approximately 21.5% of total height)
        let calfLength = personHeight * 0.215
        
        // Calculate optimal chair height (approximately equal to calf length)
        // Adding a small adjustment for shoe height and comfort (2 cm)
        let optimalChairHeight = calfLength + 2.0
        
        // Calculate optimal desk height
        // Standard elbow height while seated is about 20-30 cm above the chair
        // Using 25 cm as an average for optimal typing/working position
        let optimalDeskHeight = optimalChairHeight + 25.0
        
        return FurnitureHeights(
            chairHeight: round(optimalChairHeight * 10) / 10, // Round to 1 decimal place
            deskHeight: round(optimalDeskHeight * 10) / 10    // Round to 1 decimal place
        )
    }
    
    /// Check if current furniture heights are within ergonomic ranges
    /// - Parameters:
    ///   - personHeight: Height of the person in centimeters
    ///   - currentChairHeight: Current chair height in centimeters
    ///   - currentDeskHeight: Current desk height in centimeters
    /// - Returns: String containing analysis of current setup
    static func analyzeCurrentSetup(
        personHeight: Double,
        currentChairHeight: Double,
        currentDeskHeight: Double,
        languageSettings: LanguageSettings
    ) -> String {
        let optimal = calculateOptimalHeights(personHeight: personHeight)
        
        let chairDifference = currentChairHeight - optimal.chairHeight
        let deskDifference = currentDeskHeight - optimal.deskHeight
        
        let chairStatus = getStatusDescription(difference: chairDifference, itemName: "chair".localized(using: languageSettings), languageSettings: languageSettings)
        let deskStatus = getStatusDescription(difference: deskDifference, itemName: "desk".localized(using: languageSettings), languageSettings: languageSettings)
        
        let template = """
        Current Setup Analysis:
        
        Chair Height:
        - Current: %.1f cm
        - Optimal: %.1f cm
        %@
        
        Desk Height:
        - Current: %.1f cm
        - Optimal: %.1f cm
        %@
        """
        
        return String(format: template.localized(using: languageSettings),
                     currentChairHeight, optimal.chairHeight, chairStatus,
                     currentDeskHeight, optimal.deskHeight, deskStatus)
    }
    
    private static func getStatusDescription(difference: Double, itemName: String, languageSettings: LanguageSettings) -> String {
        let absDifference = abs(difference)
        if absDifference < 1 {
            return String(format: "✅ Your %@ height is optimal".localized(using: languageSettings), itemName)
        } else if absDifference < 2.5 {
            let direction = difference > 0 ? "lower".localized(using: languageSettings) : "higher".localized(using: languageSettings)
            return String(format: "⚠️ Consider adjusting your %@ %@ by %.1f cm".localized(using: languageSettings), itemName, direction, absDifference)
        } else {
            let direction = difference > 0 ? "too high".localized(using: languageSettings) : "too low".localized(using: languageSettings)
            return String(format: "❌ Your %@ is %@ by %.1f cm".localized(using: languageSettings), itemName, direction, absDifference)
        }
    }
} 