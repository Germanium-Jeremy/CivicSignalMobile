import SwiftUI

struct SplashView: View {
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.mainBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: geometry.size.height * 0.05) { // Adjust spacing based on screen height
                        Spacer()
                        
                        // Logo and title
                        VStack(spacing: geometry.size.height * 0.02) { // Adjust spacing dynamically
                            Image("civicsignal")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35) // Adjust size dynamically
                            Text("CIVICSIGNAL")
                                .font(AppFont.title)
                                .foregroundColor(.almostBlack)
                        }
                        
                        Spacer()
                        
                        // Buttons
                        VStack(spacing: geometry.size.height * 0.02) { // Adjust spacing dynamically
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
                        .padding(.horizontal, geometry.size.width * 0.05) // Adjust padding dynamically
                        .padding(.bottom, geometry.size.height * 0.05) // Adjust bottom padding dynamically
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)") // Preview for iPad
    }
}
