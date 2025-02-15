import Foundation

class HeightCalculator {
    /// Represents furniture measurement results in centimeters
    struct FurnitureHeights {
        let chairHeight: Double
        let deskHeight: Double
        
        var description: String {
            return """
            Recommended heights:
            - Chair height: \(String(format: "%.1f", chairHeight)) cm
            - Desk height: \(String(format: "%.1f", deskHeight)) cm
            """
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
    
    /// Get the recommended height range for furniture
    /// - Parameter personHeight: Height of the person in centimeters
    /// - Returns: String containing recommended height ranges
    static func getHeightRanges(personHeight: Double) -> String {
        let optimal = calculateOptimalHeights(personHeight: personHeight)
        
        return """
        Recommended height ranges:
        
        Chair height:
        - Minimum: \(String(format: "%.1f", optimal.chairHeight - 2)) cm
        - Optimal: \(String(format: "%.1f", optimal.chairHeight)) cm
        - Maximum: \(String(format: "%.1f", optimal.chairHeight + 2)) cm
        
        Desk height:
        - Minimum: \(String(format: "%.1f", optimal.deskHeight - 2.5)) cm
        - Optimal: \(String(format: "%.1f", optimal.deskHeight)) cm
        - Maximum: \(String(format: "%.1f", optimal.deskHeight + 2.5)) cm
        
        Note: These are recommendations based on ergonomic standards.
        Adjust within the ranges for personal comfort.
        """
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
        currentDeskHeight: Double
    ) -> String {
        let optimal = calculateOptimalHeights(personHeight: personHeight)
        
        let chairDifference = currentChairHeight - optimal.chairHeight
        let deskDifference = currentDeskHeight - optimal.deskHeight
        
        let chairStatus = getStatusDescription(difference: chairDifference, itemName: "chair")
        let deskStatus = getStatusDescription(difference: deskDifference, itemName: "desk")
        
        return """
        Current Setup Analysis:
        
        Chair Height:
        - Current: \(String(format: "%.1f", currentChairHeight)) cm
        - Optimal: \(String(format: "%.1f", optimal.chairHeight)) cm
        \(chairStatus)
        
        Desk Height:
        - Current: \(String(format: "%.1f", currentDeskHeight)) cm
        - Optimal: \(String(format: "%.1f", optimal.deskHeight)) cm
        \(deskStatus)
        """
    }
    
    private static func getStatusDescription(difference: Double, itemName: String) -> String {
        let absDifference = abs(difference)
        if absDifference < 1 {
            return "✅ Your \(itemName) height is optimal"
        } else if absDifference < 2.5 {
            let direction = difference > 0 ? "lower" : "higher"
            return "⚠️ Consider adjusting your \(itemName) \(direction) by \(String(format: "%.1f", absDifference)) cm"
        } else {
            let direction = difference > 0 ? "too high" : "too low"
            return "❌ Your \(itemName) is \(direction) by \(String(format: "%.1f", absDifference)) cm"
        }
    }
} 