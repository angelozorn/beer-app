import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    @State private var selectedImage: UIImage?
    @State private var isPickerShowing = false
    @State private var showCamera = false
    @State private var imageURL: URL?
    @State private var isProcessing = false
    @State private var username: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showSavedAlert = false

    var body: some View {
        ZStack {
            // full‐screen background from Theme.swift
            Color.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Profile image
                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.primaryAccent, lineWidth: 3)
                        )
                } else if let url = imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                        default:
                            ProgressView()
                        }
                    }
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.primaryAccent, lineWidth: 3)
                    )
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.gray)
                }

                // Username
                Text(username)
                    .font(.heading2)
                    .foregroundColor(.textPrimary)

                // Photo selection buttons
                HStack(spacing: 20) {
                    Button("Choose Photo") {
                        isPickerShowing = true
                    }
                    .font(.bodyText)
                    .foregroundColor(.primaryAccent)

                    Button("Take Photo") {
                        showCamera = true
                    }
                    .font(.bodyText)
                    .foregroundColor(.primaryAccent)
                }

                // Upload / delete
                if selectedImage != nil {
                    Button("Upload Photo") {
                        uploadProfilePhoto()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.primaryAccent)
                    .foregroundColor(Color.background)
                    .cornerRadius(10)
                }

                if imageURL != nil {
                    Button("Delete Photo") {
                        showDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }

                Spacer()
            }
            .padding()
            .onAppear(perform: fetchUserData)
            .sheet(isPresented: $isPickerShowing) {
                ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
            }
            .alert("Delete profile photo?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteProfilePhoto()
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Profile saved!", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) { }
            }

            // Loading overlay
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    ProgressView("Please wait…")
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(10)
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }

    // MARK: – Helpers

    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userDoc = Firestore.firestore()
            .collection("users")
            .document(uid)
        userDoc.getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                username = data["username"] as? String ?? ""
                if let urlStr = data["photoURL"] as? String,
                   let url = URL(string: urlStr) {
                    imageURL = url
                }
            }
        }
    }

    private func uploadProfilePhoto() {
        guard let uid = Auth.auth().currentUser?.uid,
              let img = selectedImage,
              let data = img.jpegData(compressionQuality: 0.8)
        else { return }

        isProcessing = true
        let ref = Storage.storage().reference()
            .child("profile_pictures/\(uid).jpg")

        ref.putData(data, metadata: nil) { _, error in
            isProcessing = false
            guard error == nil else { return }
            ref.downloadURL { url, _ in
                guard let url = url else { return }
                Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .updateData(["photoURL": url.absoluteString]) { _ in
                        imageURL = url
                        selectedImage = nil
                        showSavedAlert = true
                    }
            }
        }
    }

    private func deleteProfilePhoto() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isProcessing = true
        let ref = Storage.storage().reference()
            .child("profile_pictures/\(uid).jpg")

        ref.delete { error in
            isProcessing = false
            guard error == nil else { return }
            Firestore.firestore()
                .collection("users")
                .document(uid)
                .updateData(["photoURL": FieldValue.delete()]) { _ in
                    imageURL = nil
                    showSavedAlert = true
                }
        }
    }
}
