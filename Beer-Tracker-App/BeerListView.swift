import SwiftUI
import CoreData
import FirebaseAuth
import FirebaseFirestore

struct BeerListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BeerEntry.date, ascending: false)],
        animation: .default
    )
    private var beers: FetchedResults<BeerEntry>

    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                List {
                    ForEach(beers) { beer in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(beer.name ?? "")
                                .font(.heading2)
                                .foregroundColor(.textPrimary)

                            Text("\(beer.type ?? "") at \(beer.location ?? "")")
                                .font(.bodyText)
                                .foregroundColor(.textSecondary)

                            if let date = beer.date {
                                Text(date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete(perform: deleteBeers)
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle(navigationTitle)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Sign Out") {
                            authViewModel.signOut()
                        }
                        .foregroundColor(.primaryAccent)
                    }
                }
            }
        }
        .onAppear(perform: fetchUsername)
    }

    private var navigationTitle: String {
        username.isEmpty ? "Beer Log" : "\(username)'s Beer Log"
    }

    private func deleteBeers(at offsets: IndexSet) {
        offsets.map { beers[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting beers:", error.localizedDescription)
        }
    }

    private func fetchUsername() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { snapshot, _ in
                if let data = snapshot?.data(),
                   let name = data["username"] as? String {
                    username = name
                }
            }
    }
}

struct BeerListView_Previews: PreviewProvider {
    static var previews: some View {
        BeerListView()
            .environmentObject(AuthViewModel())
            .environment(\.managedObjectContext,
                PersistenceController.preview.container.viewContext
            )
    }
}
