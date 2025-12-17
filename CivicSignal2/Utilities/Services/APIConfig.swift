import Foundation

enum APIConfig {
    // For dev – your local IP
//   static let baseURL = URL(string: "http://169.254.224.202:3000/api")!

    // For prod, you can switch these or use build configs
      static let baseURL = URL(string: "https://civic-signal.vercel.app/api")!
    
//    static let baseURL = URL(string: "http://10.12.73.33:3000/api")!

    static let timeout: TimeInterval = 100 // seconds
}

// Passw0rdPassw0rd@
// Passw0rd@
// darren.rosenbaum@gmail.com
// waldo.stanton@gmail.com
