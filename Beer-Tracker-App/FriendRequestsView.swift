import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FriendRequestsView: View {
  @State private var requests: [Request] = []
  
  struct Request: Identifiable {
    let id: String
    let fromUid: String
    let timestamp: Date
    var fromUsername: String?
  }

  var body: some View {
    List {
      ForEach(requests) { req in
        HStack {
          Text(req.fromUsername ?? "…")
          Spacer()
          Button("Accept") { respond(to: req, accept: true) }
            .buttonStyle(BorderlessButtonStyle())
          Button("Deny")   { respond(to: req, accept: false) }
            .foregroundColor(.red)
            .buttonStyle(BorderlessButtonStyle())
        }
      }
    }
    .navigationTitle("Friend Requests")
    .onAppear(perform: loadRequests )
  }

  private func loadRequests() {
    guard let me = Auth.auth().currentUser?.uid else { return }
    let ref = Firestore.firestore()
      .collection("users").document(me)
      .collection("friendRequests")
      .order(by: "timestamp", descending: true)

    ref.addSnapshotListener { snap, _ in
      var new: [Request] = []
      let group = DispatchGroup()
      for doc in snap?.documents ?? [] {
        let fromUid = doc.data()["from"] as! String
        let ts = (doc.data()["timestamp"] as! Timestamp).dateValue()
        var r = Request(id: doc.documentID, fromUid: fromUid, timestamp: ts)
        group.enter()
        // Fetch sender's username
        Firestore.firestore().collection("users")
          .document(fromUid).getDocument { sd, _ in
            r.fromUsername = sd?.data()?["username"] as? String ?? "?"
            new.append(r)
            group.leave()
          }
      }
      group.notify(queue: .main) { requests = new }
    }
  }

  private func respond(to req: Request, accept: Bool) {
    guard let me = Auth.auth().currentUser?.uid else { return }
    let db = Firestore.firestore()
    let reqRef = db.collection("users")
                   .document(me)
                   .collection("friendRequests")
                   .document(req.id)

    if accept {
      let batch = db.batch()
      // 1. Add each other to friends arrays
      let meRef     = db.collection("users").document(me)
      let themRef   = db.collection("users").document(req.fromUid)
      batch.updateData(["friends": FieldValue.arrayUnion([req.fromUid])], forDocument: meRef)
      batch.updateData(["friends": FieldValue.arrayUnion([me])],        forDocument: themRef)
      // 2. Delete the request
      batch.deleteDocument(reqRef)
      batch.commit { err in
        if let e = err { print("Batch error:", e) }
      }
    } else {
      // Just delete the request
      reqRef.delete()
    }
  }
}
