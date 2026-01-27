import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage? = nil
    @State private var pickerImages: [UIImage] = []
    @State private var profileImageURL: String = ""
    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingImagePicker: Bool = false

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

                VStack(alignment: .leading, spacing: 16) {
                    Text("Profile Image")
                        .font(AppFont.body.weight(.semibold))
                        .foregroundColor(.almostBlack)
                        .padding(.horizontal, 20)

                    // Profile image preview
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.neutralGray.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else if !profileImageURL.isEmpty {
                                AsyncImage(url: URL(string: profileImageURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure, .empty:
                                        Image("civicsignal")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                    @unknown default:
                                        Image("civicsignal")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                    }
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                            } else {
                                Image("civicsignal")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                            }
                        }
                        
                        Button(action: { showingImagePicker = true }) {
                            Text(selectedImage != nil ? "Change Image" : "Select Image")
                                .font(AppFont.body.weight(.semibold))
                                .foregroundColor(.primaryBlue)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.primaryBlue, lineWidth: 1)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(images: $pickerImages, selectionLimit: 1)
        }
        .onChange(of: pickerImages) { newImages in
            selectedImage = newImages.first
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
        guard let image = selectedImage else {
            alertTitle = "Error"
            alertMessage = "Please select an image first"
            showAlert = true
            return
        }
        
        isSaving = true
        defer { isSaving = false }

        let result = await AuthService.uploadProfileImage(image)
        
        if result.success, let data = result.data {
            alertTitle = "Success"
            alertMessage = "Profile image updated successfully."
            showAlert = true
            // Update local state
            profileImageURL = data.url
            selectedImage = nil // Clear selection after successful upload
        } else {
            alertTitle = "Error"
            alertMessage = result.error ?? "Failed to update profile image."
            showAlert = true
        }
    }
}

#Preview {
    EditProfileView()
}
