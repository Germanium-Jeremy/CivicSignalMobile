import SwiftUI

enum AppFont {
    static func garamond(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        
        switch weight {
        case .bold, .heavy, .black:
            fontName = "EBGaramond-Bold"
        case .semibold, .bold:
            fontName = "EBGaramond-SemiBold"
        case .medium:
            fontName = "EBGaramond-Medium"
        default:
            fontName = "EBGaramond-Regular"
        }
        
        return Font.custom(fontName, size: size)
    }
    
    static let largeTitle = garamond(size: 34, weight: .bold)
    static let title = garamond(size: 28, weight: .bold)
    static let title2 = garamond(size: 22, weight: .semibold)
    static let title3 = garamond(size: 20, weight: .semibold)
    static let body = garamond(size: 17)
    static let callout = garamond(size: 16)
    static let subheadline = garamond(size: 15)
    static let footnote = garamond(size: 13)
    static let caption = garamond(size: 12)
    static let headline = garamond(size: 17, weight: .semibold)
    static let caption2 = garamond(size: 11)
}
