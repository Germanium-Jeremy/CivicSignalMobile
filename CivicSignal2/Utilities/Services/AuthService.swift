import Foundation

// MARK: - DTOs matching your backend

struct TokensDTO: Codable {
    let accessToken: String
    let refreshToken: String
}

struct UserDTO: Codable {
    let id: String?
    let fullName: String?
    let email: String?
    let phone: String?
    // add more fields if you know them
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

// For login we sometimes need extra info
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
    
    static func logout() {
        TokenManager.clearTokens()
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
        } catch let APIError.httpStatus(code, data) {
            let parsed = parseAuthError(from: data)
            print("Failed to send forgot password request (")
            return ServiceResult(success: false, data: nil, error: parsed.error ?? "Request failed", details: parsed.details)
        } catch {
            print("Failed to send forgot password request: \(error)")
            return ServiceResult(success: false, data: nil, error: "Request failed", details: nil)
        }
    }
}
