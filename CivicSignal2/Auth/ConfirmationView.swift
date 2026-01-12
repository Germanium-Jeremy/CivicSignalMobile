import SwiftUI

struct ConfirmationView: View {
    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo + title
                VStack(spacing: 16) {
                    Image("civicsignal")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                    
                    Text("CIVICSIGNAL")
                        .font(AppFont.title)
                        .foregroundColor(.almostBlack)
                }
                
                // Description
                Text("Your password has been updated. You can now log in to your account.")
                    .font(AppFont.body)
                    .foregroundColor(.neutralGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Button
                Button(action: {}) {
                    Text("Go to Login")
                        .font(AppFont.body.weight(.semibold))
                        .foregroundColor(.mainBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.primaryBlue)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationView {
        ConfirmationView()
    }
}
