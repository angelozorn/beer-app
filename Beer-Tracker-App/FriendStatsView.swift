import SwiftUI
import FirebaseFirestore
import Charts

struct FriendStatsView: View {
  let friendUid: String
  let friendName: String

  @State private var beers: [BeerRecord] = []
  @State private var selectedBeer: String?
  @State private var selectedDay: Date?

  struct BeerRecord: Identifiable {
    let id: String
    let name, brand, type, location: String
    let date: Date
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        Text("\(friendName)’s Stats")
          .font(.largeTitle.bold())
          .padding(.horizontal)

        // Pie & Bar charts same as StatsView but with `beers` array
        // e.g. PieChartViewRepresentable(entries: counts, …)
        // and onSelect sets selectedBeer, etc.
      }
    }
    .onAppear(perform: loadFriendBeers)
  }

  func loadFriendBeers() {
    Firestore.firestore()
      .collection("users")
      .document(friendUid)
      .collection("beers")
      .getDocuments { snap, _ in
        beers = snap?.documents.compactMap {
          let d = $0.data()
          guard
            let n = d["name"] as? String,
            let b = d["brand"] as? String,
            let t = d["type"] as? String,
            let l = d["location"] as? String,
            let ts = d["date"] as? Timestamp
          else { return nil }
          return BeerRecord(
            id: $0.documentID,
            name: n, brand: b, type: t, location: l,
            date: ts.dateValue()
          )
        } ?? []
      }
  }
}
