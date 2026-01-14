import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profileImageURL: String = ""
    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primaryBlue)
                    }
                    Spacer()
                    Text("Edit Profile")
                        .font(AppFont.title3)
                        .foregroundColor(.almostBlack)
                    Spacer()
                    Spacer().frame(width: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Profile Image URL")
                        .font(AppFont.body.weight(.semibold))
                        .foregroundColor(.almostBlack)

                    TextField("https://example.com/image.jpg", text: $profileImageURL)
                        .font(AppFont.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer()

                Button(action: {
                    Task { await saveProfile() }
                }) {
                    Text(isSaving ? "Saving..." : "Save")
                        .font(AppFont.body.weight(.semibold))
                        .foregroundColor(.mainBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(isSaving ? Color.primaryBlue.opacity(0.7) : Color.primaryBlue)
                        .cornerRadius(20)
                }
                .disabled(isSaving)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            if let user: UserDTO = TokenManager.getUserData(UserDTO.self),
               let current = user.profileImage {
                profileImageURL = current
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if alertTitle == "Success" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func saveProfile() async {
        isSaving = true
        defer { isSaving = false }

        struct UpdateProfileBody: Encodable {
            let profileImage: String
        }

        do {
            let response = try await APIClient.shared.request(
                "user/profile",
                method: "PATCH",
                body: UpdateProfileBody(profileImage: profileImageURL),
                authorized: true,
                responseType: AuthBaseResponse.self
            )

            if let updatedUser = response.user {
                TokenManager.saveUserData(updatedUser)
            }

            alertTitle = "Success"
            alertMessage = "Profile image updated successfully."
            showAlert = true
        } catch let APIError.httpStatus(_, data) {
            let parsed = AuthService.parseError(from: data)
            alertTitle = "Error"
            alertMessage = parsed.error ?? "Failed to update profile."
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    EditProfileView()
}
