import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FriendsListView: View {
  @State private var friends: [(uid:String, username:String)] = []

  var body: some View {
    List {
      ForEach(friends, id: \.uid) { friend in
        NavigationLink(friend.username) {
          FriendStatsView(friendUid: friend.uid, friendName: friend.username)
        }
      }
    }
    .navigationTitle("Friends")
    .onAppear(perform: loadFriends)
  }

    private func loadFriends() {
      guard let me = Auth.auth().currentUser?.uid else { return }
      let userRef = Firestore.firestore()
                         .collection("users")
                         .document(me)

      userRef.addSnapshotListener { snap, _ in
        // 1. Get the raw friends list (might contain empty strings)
        let raw = snap?.data()?["friends"] as? [String] ?? []

        // 2. Trim whitespace and drop any blank entries
        let uids = raw
          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { !$0.isEmpty }

        // 3. If nothing left, clear and bail
        guard !uids.isEmpty else {
          self.friends = []
          return
        }

        // 4. Otherwise safely query Firestore
        Firestore.firestore()
          .collection("users")
          .whereField(FieldPath.documentID(), in: uids)
          .getDocuments { snapshot, error in
            guard let docs = snapshot?.documents, error == nil else {
              self.friends = []
              return
            }
            self.friends = docs.map { doc in
              let name = doc.data()["username"] as? String ?? "—"
              return (uid: doc.documentID, username: name)
            }
          }
      }
    }
}
