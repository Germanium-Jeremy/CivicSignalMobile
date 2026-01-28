import Foundation
import UIKit

struct TokensDTO: Codable {
    let accessToken: String
    let refreshToken: String
}

struct UserDTO: Codable {
    let id: String?
    let fullName: String?
    let email: String?
    let phone: String?
    let profileImage: String?
}

struct AuthBaseResponse: Codable {
    let tokens: TokensDTO?
    let user: UserDTO?
    let error: String?
    let details: String?
    let message: String?
    let fullyVerified: Bool?
    let identifier: String?
    
    // For the 403 verification-required case
    let requiresVerification: Bool?
    let emailVerified: Bool?
    let phoneVerified: Bool?
    let email: String?
    let phone: String?
    let codesSent: Bool?
}

// For register
struct RegisterRequest: Encodable {
    let fullName: String
    let email: String
    let phone: String
    let password: String
}

// For login
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

// For verify / resend
struct VerifyEmailRequest: Encodable {
    let email: String
    let code: String
}

struct VerifyPhoneRequest: Encodable {
    let phone: String
    let code: String
}

struct ResendEmailRequest: Encodable {
    let email: String
}

struct ResendPhoneRequest: Encodable {
    let phone: String
}

struct VerificationRequiredInfo {
	let emailVerified: Bool
	let phoneVerified: Bool
	let email: String?
	let phone: String?
	let message: String?
	let codesSent: Bool
}

struct LoginResult {
    let success: Bool
    let data: AuthBaseResponse?
    let error: String?
    let requiresVerification: Bool
    let verificationInfo: VerificationRequiredInfo?
}

// MARK: - AuthService

enum AuthService {
    
    // MARK: Register
    
    static func register(fullName: String, email: String, phone: String, password: String) async -> ServiceResult<AuthBaseResponse> {
        let body = RegisterRequest(fullName: fullName, email: email, phone: phone, password: password)
        
        do {
            let response = try await APIClient.shared.request(
                "auth/register",
                method: "POST",
                body: body,
                authorized: false,
                responseType: AuthBaseResponse.self
            )

            print("Registered User: \(response)")
            
            return ServiceResult(success: true, data: response, error: nil, details: response.details)
        } catch let APIError.httpStatus(code, data) {
            let parsed = parseAuthError(from: data)
                print("Failed to Register (\(code)): \(parsed.error ?? "unknown")")
            return ServiceResult(success: false, data: nil, error: parsed.error ?? "Registration failed", details: parsed.details)
        } catch {
            print("error during register: \(error)")
            return ServiceResult(success: false, data: nil, error: error.localizedDescription, details: nil)
        }
    }
    
    // MARK: Verify email
    
    static func verifyEmail(email: String, code: String) async -> ServiceResult<AuthBaseResponse> {
        let body = VerifyEmailRequest(email: email, code: code)
        
        do {
            let response = try await APIClient.shared.request(
                "auth/verify-email",
                method: "POST",
                body: body,
                authorized: false,
                responseType: AuthBaseResponse.self
            )
            
            if let tokens = response.tokens {
                TokenManager.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
            }
            if let user = response.user {
                TokenManager.saveUserData(user)
            }
            
            return ServiceResult(success: true, data: response, error: nil, details: response.details)
        } catch let APIError.httpStatus(code, data) {
            let parsed = parseAuthError(from: data)
            print("Failed to verify email (\(code)): \(parsed.error ?? "unknown")")
            return ServiceResult(success: false, data: nil, error: parsed.error ?? "Verification failed", details: parsed.details)
        } catch {
            print("Failed to verify email: \(error)")
            return ServiceResult(success: false, data: nil, error: "Verification failed", details: nil)
        }
    }
    
    // MARK: Verify phone
    
    static func verifyPhone(phone: String, code: String) async -> ServiceResult<AuthBaseResponse> {
        let body = VerifyPhoneRequest(phone: phone, code: code)
        
        do {
            let response = try await APIClient.shared.request(
                "auth/verify-phone",
                method: "POST",
                body: body,
                authorized: false,
                responseType: AuthBaseResponse.self
            )
            
            if let tokens = response.tokens {
                TokenManager.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
            }
            if let user = response.user {
                TokenManager.saveUserData(user)
            }
            
            return ServiceResult(success: true, data: response, error: nil, details: response.details)
        } catch let APIError.httpStatus(code, data) {
            let parsed = parseAuthError(from: data)
            print("Failed to verify phone (\(code)): \(parsed.error ?? "unknown")")
            return ServiceResult(success: false, data: nil, error: parsed.error ?? "Verification failed", details: parsed.details)
        } catch {
            print("Failed to verify phone: \(error)")
            return ServiceResult(success: false, data: nil, error: "Verification failed", details: nil)
        }
    }
    
    // MARK: Resend codes
    
    static func resendEmailCode(email: String) async -> ServiceResult<AuthBaseResponse> {
        let body = ResendEmailRequest(email: email)
        
        do {
            let response = try await APIClient.shared.request(
                "auth/verify-email",
                method: "PATCH",
                body: body,
                authorized: false,
                responseType: AuthBaseResponse.self
            )
            return ServiceResult(success: true, data: response, error: nil, details: response.details)
        } catch let APIError.httpStatus(code, data) {
            let parsed = parseAuthError(from: data)
            print("Failed to resend email code (\(code)): \(parsed.error ?? "unknown")")
            return ServiceResult(success: false, data: nil, error: parsed.error ?? "Failed to resend code", details: parsed.details)
        } catch {
            print("Failed to resend email code: \(error)")
            return ServiceResult(success: false, data: nil, error: "Failed to resend code", details: nil)
        }
    }
    
    static func resendPhoneCode(phone: String) async -> ServiceResult<AuthBaseResponse> {
        let body = ResendPhoneRequest(phone: phone)
        
        do {
            let response = try await APIClient.shared.request(
                "auth/verify-phone",
                method: "PATCH",
                body: body,
                authorized: false,
                responseType: AuthBaseResponse.self
            )
            return ServiceResult(success: true, data: response, error: nil, details: response.details)
        } catch let APIError.httpStatus(code, data) {
            let parsed = parseAuthError(from: data)
            print("Failed to resend phone code (\(code)): \(parsed.error ?? "unknown")")
            return ServiceResult(success: false, data: nil, error: parsed.error ?? "Failed to resend code", details: parsed.details)
        } catch {
            print("Failed to resend phone code: \(error)")
            return ServiceResult(success: false, data: nil, error: "Failed to resend code", details: nil)
        }
    }
    
    // MARK: Login
    
    static func login(email: String, password: String) async -> LoginResult {
        let body = LoginRequest(email: email, password: password)
        
        do {
            let response = try await APIClient.shared.request(
                "auth/login",
                method: "POST",
                body: body,
                authorized: false,
                responseType: AuthBaseResponse.self
            )
            
            if let tokens = response.tokens {
                TokenManager.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
            }
            if let user = response.user {
                TokenManager.saveUserData(user)
            }
            
            return LoginResult(
                success: true,
                data: response,
                error: nil,
                requiresVerification: false,
                verificationInfo: nil
            )
        } catch let APIError.httpStatus(code, data) {
            // Handle 403 special case like TS service
            if code == 403 {
                let parsed = parseAuthError(from: data)
                
                if parsed.requiresVerification == true {
                    let info = VerificationRequiredInfo(
                        emailVerified: parsed.emailVerified ?? false,
                        phoneVerified: parsed.phoneVerified ?? false,
                        email: parsed.email,
                        phone: parsed.phone,
                        message: parsed.message,
                        codesSent: parsed.codesSent ?? false
                    )
                    
                    return LoginResult(
                        success: false,
                        data: nil,
                        error: "Account not verified",
                        requiresVerification: true,
                        verificationInfo: info
                    )
                }
            }
            
            let parsed = parseAuthError(from: data)
            print("Failed to login (\(code)): \(parsed.error ?? "unknown")")
            return LoginResult(
                success: false,
                data: nil,
                error: parsed.error ?? "Login failed",
                requiresVerification: false,
                verificationInfo: nil
            )
        } catch {
            print("Failed to login: \(error)")
            return LoginResult(
                success: false,
                data: nil,
                error: "Login failed",
                requiresVerification: false,
                verificationInfo: nil
            )
        }
    }
    
    // MARK: Logout / token helpers

    struct LogoutRequest: Encodable {
        let refreshToken: String?
        let logoutAll: Bool
    }

    struct LogoutResponse: Codable {
        let success: Bool?
        let message: String?
        let error: String?
    }

    /// Call backend logout endpoint and clear local tokens.
    static func logout(logoutAll: Bool = false) async -> ServiceResult<LogoutResponse> {
        let body = LogoutRequest(refreshToken: TokenManager.refreshToken, logoutAll: logoutAll)

        do {
            let response = try await APIClient.shared.request(
                "auth/logout",
                method: "POST",
                body: body,
                authorized: true,
                responseType: LogoutResponse.self
            )

            TokenManager.clearTokens()
            return ServiceResult(
                success: response.success ?? true,
                data: response,
                error: nil,
                details: response.message
            )
        } catch let APIError.httpStatus(_, data) {
            // Try to parse error but still clear tokens locally
            let decoder = JSONDecoder()
            let parsed = (try? decoder.decode(LogoutResponse.self, from: data)) ?? LogoutResponse(success: false, message: nil, error: nil)
            TokenManager.clearTokens()
            return ServiceResult(
                success: false,
                data: parsed,
                error: parsed.error ?? "Logout failed",
                details: parsed.message
            )
        } catch {
            TokenManager.clearTokens()
            return ServiceResult(
                success: false,
                data: nil,
                error: "Logout failed",
                details: nil
            )
        }
    }

    static func isLoggedIn() -> Bool {
        return TokenManager.accessToken != nil
    }
    
    static func getCurrentUser() -> UserDTO? {
        TokenManager.getUserData(UserDTO.self)
    }
    
    // MARK: - Helper
    
    private static func parseAuthError(from data: Data) -> AuthBaseResponse {
        let decoder = JSONDecoder()
        return (try? decoder.decode(AuthBaseResponse.self, from: data)) ?? AuthBaseResponse(
            tokens: nil,
            user: nil,
            error: nil,
            details: nil,
            message: nil,
            fullyVerified: nil,
            identifier: nil,
            requiresVerification: nil,
            emailVerified: nil,
            phoneVerified: nil,
            email: nil,
            phone: nil,
            codesSent: nil
        )
    }
    
    // MARK: Forgot Password

    static func forgotPassword(email: String) async -> ServiceResult<AuthBaseResponse> {
        let body = ["email": email]

        do {
            let response = try await APIClient.shared.request(
                "auth/forgot-password",
                method: "POST",
                body: body,
                authorized: false,
                responseType: AuthBaseResponse.self
            )

            return ServiceResult(success: true, data: response, error: nil, details: response.details)
        } catch let APIError.httpStatus(_, data) {
            let parsed = parseAuthError(from: data)
            print("Failed to send forgot password request (")
            return ServiceResult(success: false, data: nil, error: parsed.error ?? "Request failed", details: parsed.details)
        } catch {
            print("Failed to send forgot password request: \(error)")
            return ServiceResult(success: false, data: nil, error: "Request failed", details: nil)
        }
    }
    
    // MARK: Upload Profile Image
    
    struct UploadProfileImageRequest: Encodable {
        struct Image: Encodable {
            let data: String
            let mimeType: String
        }
        let image: Image
    }
    
    struct UploadProfileImageResponse: Codable {
        let success: Bool
        let message: String?
        let data: DataField?
        struct DataField: Codable {
            let url: String
            let size: Int?
            let mimeType: String?
        }
    }
    
    static func uploadProfileImage(_ image: UIImage) async -> ServiceResult<UploadProfileImageResponse.DataField> {
        // Convert UIImage to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) ?? image.pngData() else {
            return ServiceResult(success: false, data: nil, error: "Failed to convert image to data", details: nil)
        }
        
        let mimeType = imageData == image.jpegData(compressionQuality: 0.8) ? "image/jpeg" : "image/png"
        let base64String = imageData.base64EncodedString()
        
        let body = UploadProfileImageRequest(image: UploadProfileImageRequest.Image(data: base64String, mimeType: mimeType))
        
        do {
            let response = try await APIClient.shared.request(
                "user/profile/upload",
                method: "POST",
                body: body,
                authorized: true,
                responseType: UploadProfileImageResponse.self
            )
            
            // Update local user data if response includes URL
            if let data = response.data {
                if let user: UserDTO = TokenManager.getUserData(UserDTO.self) {
                    // Create updated user with new profile image
                    let updatedUser = UserDTO(
                        id: user.id,
                        fullName: user.fullName,
                        email: user.email,
                        phone: user.phone,
                        profileImage: data.url
                    )
                    TokenManager.saveUserData(updatedUser)
                }
            }
            
            if let data = response.data {
                return ServiceResult(success: true, data: data, error: nil, details: response.message)
            } else {
                return ServiceResult(success: false, data: nil, error: "No data in response", details: nil)
            }
        } catch let APIError.httpStatus(code, data) {
            let parsed = parseAuthError(from: data)
            print("Failed to upload profile image (\(code)): \(parsed.error ?? "unknown")")
            return ServiceResult(success: false, data: nil, error: parsed.error ?? "Failed to upload profile image", details: parsed.details)
        } catch {
            print("Failed to upload profile image: \(error)")
            return ServiceResult(success: false, data: nil, error: "Failed to upload profile image", details: nil)
        }
    }
}

// MARK: - Profile Image Management
extension AuthService {
    private static let profileImageDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ProfileImages")
    }()

    static func saveProfileImage(_ image: UIImage, for userId: String) {
        do {
            let directory = profileImageDirectory
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }

            let imagePath = directory.appendingPathComponent("")
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                try imageData.write(to: imagePath)
            }
        } catch {
            print("Failed to save profile image: \(error.localizedDescription)")
        }
    }

    static func getProfileImage(for userId: String) -> UIImage? {
        let imagePath = profileImageDirectory.appendingPathComponent("")
        if FileManager.default.fileExists(atPath: imagePath.path) {
            return UIImage(contentsOfFile: imagePath.path)
        }
        return nil
    }
}
