import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddFriendView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var usernameToAdd = ""
    @State private var statusMessage: String?
    @State private var isSending     = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Enter username")) {
                    TextField("Username", text: $usernameToAdd)
                        .autocapitalization(.none)
                }

                if let msg = statusMessage {
                    Section {
                        Text(msg)
                            .foregroundColor(msg.hasPrefix("✅") ? .green : .red)
                    }
                }

                Section {
                    Button(action: sendRequest) {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Send Friend Request")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .disabled(usernameToAdd.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
            }
            .navigationTitle("Add Friend")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }

    private func sendRequest() {
        let name = usernameToAdd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty,
              let me = Auth.auth().currentUser?.uid
        else { return }

        isSending = true
        statusMessage = nil

        let usersRef = Firestore.firestore().collection("users")
        // 1) lookup the user by username
        usersRef
          .whereField("username", isEqualTo: name)
          .limit(to: 1)
          .getDocuments { snapshot, error in
            defer { isSending = false }

            if let err = error {
              statusMessage = "❌ \(err.localizedDescription)"
              return
            }
            guard let doc = snapshot?.documents.first else {
              statusMessage = "❌ No user “\(name)” found."
              return
            }
            let receiverUid = doc.documentID
            // Prevent sending to self
            if receiverUid == me {
              statusMessage = "❌ You can’t friend yourself."
              return
            }
            // 2) write a friendRequests doc under that user
            let reqRef = usersRef
              .document(receiverUid)
              .collection("friendRequests")
              .document()    // auto-ID

            reqRef.setData([
              "fromUid":     me,
              "fromUsername": doc.data()["username"] as? String ?? "",
              "timestamp":   FieldValue.serverTimestamp()
            ]) { err in
              if let err = err {
                statusMessage = "❌ \(err.localizedDescription)"
              } else {
                statusMessage = "✅ Request sent to \(name)!"
              }
            }
        }
    }
}
