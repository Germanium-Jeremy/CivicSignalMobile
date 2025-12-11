import SwiftUI

struct SplashView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Logo and title
                    VStack(spacing: 16) {
                        Image("civicsignal")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                        Text("CIVICSIGNAL")
                            .font(AppFont.title)
                            .foregroundColor(.almostBlack)
                    }
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 16) {
                        NavigationLink(destination: LoginView()) {
                            Text("Login")
                                .font(AppFont.body.weight(.semibold))
                                .foregroundColor(.mainBackground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.primaryBlue)
                                .cornerRadius(20)
                        }
                        
                        NavigationLink(destination: RegisterView()) {
                            Text("Register")
                                .font(AppFont.body.weight(.semibold))
                                .foregroundColor(.almostBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.lightGray)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
