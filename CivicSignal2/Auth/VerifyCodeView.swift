import SwiftUI

struct VerifyCodeView: View {
    @State private var code: String = ""
    
    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text("Enter your email or phone")
                        .font(AppFont.title)
                        .foregroundColor(.almostBlack)
                    
                    // Description
                    Text("A code was sent to your email or phone via messages. Enter the code here. The code expired in 5 minutes.")
                        .font(AppFont.body)
                        .foregroundColor(.neutralGray)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Code field
                    TextField("Code", text: $code)
                        .font(AppFont.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
                        )
                        .frame(maxWidth: 600)
                    
                    // Continue button
                    Button(action: {}) {
                        Text("Continue")
                            .font(AppFont.body.weight(.semibold))
                            .foregroundColor(.mainBackground)
                            .frame(maxWidth: 600) // Limit width for larger screens
                            .padding(.horizontal, 16) // Add padding for smaller screens
                            .padding(.vertical, 15)
                            .background(Color.primaryBlue)
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Bottom text
                HStack {
                    Text("Didn’t receive the code?")
                        .font(AppFont.footnote)
                        .foregroundColor(.neutralGray)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationView {
        VerifyCodeView()
    }
}
