import SwiftUI
import UIKit

struct ReportEvidenceView: View {
    @ObservedObject var draft: ReportDraft
    let issueId: String
    @State private var images: [UIImage] = []
    @State private var showingPicker = false
    @State private var isSubmitting = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Add supportive evidence")
                            .font(AppFont.title)
                            .foregroundColor(.almostBlack)
                            .padding(.top, 24)

                        // Selected images preview
                        if !images.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(images.enumerated()), id: \.offset) { idx, img in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(12)
                                            Button(action: { images.remove(at: idx) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Circle().fill(Color.white))
                                            }
                                            .offset(x: 6, y: -6)
                                        }
                                    }
                                }
                            }
                        }

                        Button(action: { showingPicker = true }) {
                            evidenceButton(title: "Upload Images")
                        }

                        // (Optional placeholders)
                        evidenceButton(title: "Record Audio")
                        evidenceButton(title: "Record Video")

                        Text("Supportive media files are optional, in case they are not available, you can just submit without them.")
                            .font(AppFont.body)
                            .foregroundColor(.neutralGray)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(action: { Task { await handleSubmit() } }) {
                            Text(isSubmitting ? "Submitting..." : "Submit")
                                .font(AppFont.body.weight(.semibold))
                                .foregroundColor(.mainBackground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(isSubmitting ? Color.primaryBlue.opacity(0.6) : Color.primaryBlue)
                                .cornerRadius(20)
                        }
                        .disabled(isSubmitting)
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20)
                    .padding(.bottom, 80)
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            ImagePicker(images: $images, selectionLimit: 5)
        }
        .alert(alertTitle, isPresented: $showAlert) { Button("OK", role: .cancel) {} } message: { Text(alertMessage) }
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.lightGray)
                    .frame(width: 40, height: 40)
                Image("civicsignal")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }

            Spacer()

            Text("Report")
                .font(AppFont.title3)
                .foregroundColor(.almostBlack)

            Spacer()

            // Placeholder to keep header layout without notifications feature
            ZStack {
                Circle()
                    .stroke(Color.secondaryGreen.opacity(0.0), lineWidth: 2)
                    .background(Circle().fill(Color.mainBackground))
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 20)
        .padding(.top, 12)
    }

    private func evidenceButton(title: String) -> some View {
        HStack {
            Text(title)
                .font(AppFont.body)
                .foregroundColor(.almostBlack)
            Spacer()
            Text("(optional)")
                .font(AppFont.footnote)
                .foregroundColor(.neutralGray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.accentGreen.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Submission
    private func handleSubmit() async {
        isSubmitting = true
        defer { isSubmitting = false }

        // Upload images if any and PATCH to existing issue
        if !images.isEmpty {
            let compressed = images.prefix(5).compactMap { img -> UploadPhotosRequest.Image? in
                guard let data = img.jpegData(compressionQuality: 0.8) else { return nil }
                return UploadPhotosRequest.Image(data: data.base64EncodedString(), mimeType: "image/jpeg")
            }
            let up = await IssueService.uploadPhotos(compressed)
            if up.success, let photos = up.data {
                let patch = await IssueService.updateIssuePhotos(issueId: issueId, photos: photos)
                if !patch.success {
                    alertTitle = "Update Failed"; alertMessage = patch.error ?? "Failed to attach photos"; showAlert = true; return
                }
            } else {
                alertTitle = "Upload Failed"; alertMessage = up.error ?? "Failed to upload photos"; showAlert = true; return
            }
        }

        alertTitle = "Done"
        alertMessage = images.isEmpty ? "Issue submitted without media." : "Photos attached to your issue."
        showAlert = true
    }
}

#Preview {
    ReportEvidenceView(draft: ReportDraft(), issueId: "demo-id")
}
