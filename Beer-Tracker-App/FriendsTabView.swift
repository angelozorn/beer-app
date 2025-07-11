import SwiftUI

struct FriendsTabView: View {
    @State private var selection      = 0
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            VStack {
                Picker("", selection: $selection) {
                    Text("Requests").tag(0)
                    Text("Friends").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                if selection == 0 {
                    FriendRequestsView()
                } else {
                    FriendsListView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showingAddSheet = true
                                } label: {
                                    Image(systemName: "person.badge.plus")
                                }
                                .accessibilityLabel("Add Friend")
                            }
                        }
                }

                Spacer()
            }
            .navigationTitle("Friends")
            .sheet(isPresented: $showingAddSheet) {
                AddFriendView()
            }
        }
    }
}
