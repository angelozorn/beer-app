import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        ZStack {
            // full‐screen background from Theme.swift
            Color.background
                .ignoresSafeArea()

            if authViewModel.isUserLoggedIn {
                TabView {
                    FriendsTabView()
                        .tabItem {
                            Label("Friends", systemImage: "person.2.fill")
                        }

                    StatsView()
                        .tabItem {
                            Label("Stats", systemImage: "chart.pie.fill")
                        }

                    BeerListView()
                        .tabItem {
                            Label("Beers", systemImage: "list.bullet")
                        }

                    AddBeerView()
                        .tabItem {
                            Label("Add Beer", systemImage: "plus.circle")
                        }

                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                }
                .accentColor(.primaryAccent)
            } else {
                AuthView(onLoginSuccess: {
                    authViewModel.isUserLoggedIn = true
                })
            }
        }
        .environmentObject(authViewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
            .environment(\.managedObjectContext,
                         PersistenceController.preview.container.viewContext)
    }
}
