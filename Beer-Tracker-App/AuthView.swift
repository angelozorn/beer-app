import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthView: View {
    /// Called when login or signup succeeds
    var onLoginSuccess: () -> Void

    @State private var email        = ""
    @State private var password     = ""
    @State private var username     = ""
    @State private var isSigningUp  = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // full-screen background
            Color.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                Text(isSigningUp ? "Create Account" : "Sign In")
                    .font(.heading1)
                    .foregroundColor(.textPrimary)

                // Input fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                        .foregroundColor(.textPrimary)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                        .foregroundColor(.textPrimary)

                    if isSigningUp {
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.cardBackground)
                            .cornerRadius(8)
                            .foregroundColor(.textPrimary)
                    }
                }

                // Submit button
                Button(action: submit) {
                    Text(isSigningUp ? "Sign Up" : "Log In")
                        .font(.heading2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryAccent)
                        .cornerRadius(8)
                        .foregroundColor(.background)
                }

                // Toggle between login / signup
                Button(action: {
                    isSigningUp.toggle()
                    errorMessage = ""
                }) {
                    Text(isSigningUp
                         ? "Already have an account? Sign In"
                         : "Don't have an account? Create one")
                        .font(.caption)
                        .foregroundColor(.secondaryAccent)
                }

                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
    }

    private func submit() {
        errorMessage = ""
        if isSigningUp {
            signUp()
        } else {
            signIn()
        }
    }

    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let e = error {
                errorMessage = e.localizedDescription
            } else {
                onLoginSuccess()
            }
        }
    }

    private func signUp() {
        // Require a username
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a username."
            return
        }

        let db = Firestore.firestore().collection("users")
        // Check uniqueness
        db.whereField("username", isEqualTo: username)
          .getDocuments { snapshot, error in
            if let e = error {
                errorMessage = e.localizedDescription
                return
            }
            if let docs = snapshot?.documents, !docs.isEmpty {
                errorMessage = "Username is already taken."
                return
            }
            // Create Auth user
            Auth.auth().createUser(withEmail: email, password: password) { res, err in
                if let e = err {
                    errorMessage = e.localizedDescription
                    return
                }
                guard let uid = res?.user.uid else { return }
                // Save user record
                let data: [String:Any] = [
                    "uid":      uid,
                    "email":    email,
                    "username": username
                ]
                db.document(uid).setData(data) { e in
                    if let e = e {
                        errorMessage = e.localizedDescription
                    } else {
                        onLoginSuccess()
                    }
                }
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView {}  // no-op onLogin
            .previewDevice("iPhone 14")
    }
}
