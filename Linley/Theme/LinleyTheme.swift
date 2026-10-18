import SwiftUI

enum LinleyTheme {
    static let coral = Color(red: 1.00, green: 0.55, blue: 0.62)
    static let coralDeep = Color(red: 1.00, green: 0.37, blue: 0.45)
    static let plum = Color(red: 0.29, green: 0.14, blue: 0.31)
    static let cream = Color(red: 1.00, green: 0.94, blue: 0.96)
    static let gold = Color(red: 1.00, green: 0.78, blue: 0.34)
    static let mint = Color(red: 0.44, green: 0.84, blue: 0.70)
    static let orange = Color(red: 1, green: 0.56, blue: 0.24)
    static let sky = Color(red: 0.44, green: 0.74, blue: 0.96)

    static let pageGradient = LinearGradient(
        colors: [cream, Color.white, coral.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [coralDeep, coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum LinleyCopy {
    static let appName = "Linley"
    static let tagline = "Little moments. Big imagination."
    static let version = "Prototype 0.4.9"
}
