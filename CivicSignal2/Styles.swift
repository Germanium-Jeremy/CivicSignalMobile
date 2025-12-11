import SwiftUI

struct AppStyles {
    // MARK: - Backgrounds
    static let mainBackground = Color.mainBackground
    static let authBackground = Color.mainBackground
    
    // MARK: - Buttons
    struct Buttons {
        static func mainButtonStyle(isDark: Bool = false) -> some ViewModifier {
            return ButtonStyleModifier(
                backgroundColor: isDark ? .almostBlack : .primaryBlue,
                foregroundColor: .white,
                font: .custom("EBGaramond-Bold", size: 18),
                height: 50,
                cornerRadius: 20
            )
        }
        
        static func subButtonStyle(isDark: Bool = false) -> some ViewModifier {
            return ButtonStyleModifier(
                backgroundColor: isDark ? .neutralGray : .lightGray,
                foregroundColor: .almostBlack,
                font: .custom("EBGaramond-Medium", size: 15),
                height: 50,
                cornerRadius: 20
            )
        }
    }
    
    // MARK: - Text Styles
    struct TextStyles {
        static let authTitle = TextStyle(
            font: .custom("EBGaramond-Medium", size: 24),
            color: .almostBlack
        )
        
        static let normal = TextStyle(
            font: .custom("EBGaramond", size: 16),
            color: .almostBlack
        )
    }
    
    // MARK: - Layout
    struct Layout {
        static let horizontalPadding: CGFloat = 15
        static let verticalPadding: CGFloat = 20
        static let buttonHeight: CGFloat = 50
        static let cornerRadius: CGFloat = 20
    }
}

// MARK: - Supporting Types
struct ButtonStyleModifier: ViewModifier {
    let backgroundColor: Color
    let foregroundColor: Color
    let font: Font
    let height: CGFloat
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
    }
}

struct TextStyle {
    let font: Font
    let color: Color
}

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.color)
    }
}
