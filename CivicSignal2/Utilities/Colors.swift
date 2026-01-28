import SwiftUI

extension Color {
    // Main Colors
    static let primaryBlue = Color(hex: "#0B3954")
    static let neutralGray = Color(hex: "#4F5D75")
    static let accentGreen = Color(hex: "#00A896")
    static let secondaryGreen = Color(hex: "#02C39A")
    static let lightGray = Color(hex: "#EAEDF0")
    static let mainBackground = Color(hex: "#FFFFFF")
    static let errorRed = Color(hex: "#E63946")
    static let warningYellow = Color(hex: "#FFB703")
    static let almostBlack = Color(hex: "#010D15")
    static let acknowledgedBrown = Color(hex: "#7e2a0c")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
