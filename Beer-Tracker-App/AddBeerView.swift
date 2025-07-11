import SwiftUI
import CoreData
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: – Master-beer model
struct BeerMaster: Identifiable, Codable {
    let id: String          // Firestore document ID
    let name: String
    let assetName: String   // must match an image in Assets.xcassets
    let photoURL: String?   // optional user-uploaded URL
}

struct AddBeerView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // — Form fields —
    @State private var beerName    = ""
    @State private var type        = "Can"
    @State private var location    = "Home"
    @State private var friendOrBar = ""

    // — Image picking —
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    // — Autocomplete state —
    @State private var masterBeers: [BeerMaster]   = []
    @State private var filteredBeers: [BeerMaster] = []
    @State private var showAddNew    = false

    // — Picker options —
    let types     = ["Can", "Bottle", "Draft"]
    let locations = ["Home", "Friend's House", "Bar or Restaurant"]

    var body: some View {
        NavigationView {
            ZStack {
                // background color from our Theme.swift
                Color.background
                    .ignoresSafeArea()

                Form {
                    // MARK: Beer Info
                    Section(header:
                        Text("Beer Info")
                            .font(.heading2)
                            .foregroundColor(.textPrimary)
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Beer Name", text: $beerName)
                                .font(.bodyText)
                                .padding(8)
                                .background(Color.cardBackground)
                                .cornerRadius(8)
                                .foregroundColor(.textPrimary)
                                .autocapitalization(.words)
                                .onChange(of: beerName) { _ in filterBeers() }

                            if !filteredBeers.isEmpty {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(filteredBeers) { beer in
                                            HStack {
                                                if let urlStr = beer.photoURL,
                                                   let url = URL(string: urlStr) {
                                                    AsyncImage(url: url) { img in
                                                        img.resizable()
                                                    } placeholder: {
                                                        Color.cardBackground
                                                    }
                                                    .frame(width: 30, height: 30)
                                                    .cornerRadius(4)
                                                } else {
                                                    Image(beer.assetName)
                                                        .resizable()
                                                        .frame(width: 30, height: 30)
                                                        .cornerRadius(4)
                                                }
                                                Text(beer.name)
                                                    .font(.bodyText)
                                                    .foregroundColor(.textPrimary)
                                                    .padding(.leading, 8)
                                            }
                                            .padding(6)
                                            .background(Color.cardBackground)
                                            .cornerRadius(8)
                                            .onTapGesture { select(beer) }
                                        }
                                    }
                                }
                                .frame(maxHeight: 150)
                            }

                            if showAddNew {
                                Button("Add \"\(beerName)\" to master list") {
                                    addNewBeer()
                                }
                                .font(.caption)
                                .foregroundColor(.secondaryAccent)
                            }
                        }

                        Picker("Type", selection: $type) {
                            ForEach(types, id: \.self) {
                                Text($0).font(.bodyText).foregroundColor(.textPrimary)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(.primaryAccent)

                        Picker("Where?", selection: $location) {
                            ForEach(locations, id: \.self) {
                                Text($0).font(.bodyText).foregroundColor(.textPrimary)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(.primaryAccent)
                        .onChange(of: location) { _ in friendOrBar = "" }

                        if location != "Home" {
                            TextField(
                                location == "Friend's House"
                                    ? "Friend’s Name"
                                    : "Bar/Restaurant Name",
                                text: $friendOrBar
                            )
                            .font(.bodyText)
                            .padding(8)
                            .background(Color.cardBackground)
                            .cornerRadius(8)
                            .foregroundColor(.textPrimary)
                        }
                    }
                    .listRowBackground(Color.background)

                    // MARK: Photo upload
                    Section(header:
                        Text("Photo (optional)")
                            .font(.heading2)
                            .foregroundColor(.textPrimary)
                    ) {
                        if let img = selectedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        HStack {
                            Button {
                                imagePickerSource = .camera
                                showingImagePicker = true
                            } label: {
                                Label("Camera", systemImage: "camera")
                                    .font(.bodyText)
                                    .foregroundColor(.primaryAccent)
                            }
                            Spacer()
                            Button {
                                imagePickerSource = .photoLibrary
                                showingImagePicker = true
                            } label: {
                                Label("Library", systemImage: "photo.on.rectangle")
                                    .font(.bodyText)
                                    .foregroundColor(.primaryAccent)
                            }
                        }
                    }
                    .listRowBackground(Color.background)

                    // MARK: Save entry
                    Section {
                        Button {
                            saveBeer()
                        } label: {
                            Text("Save Beer")
                                .font(.heading2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primaryAccent)
                                .cornerRadius(12)
                                .foregroundColor(.background)
                        }
                    }
                    .listRowBackground(Color.background)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add New Beer")
            .onAppear(perform: loadMasterBeers)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(
                    sourceType: imagePickerSource,
                    selectedImage: $selectedImage
                )
            }
        }
    }

    // MARK: – Load & Autocomplete

    private func loadMasterBeers() {
        masterBeers.removeAll()
        // Bundled JSON
        if let url = Bundle.main.url(forResource: "top_beers", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let locals = try? JSONDecoder().decode([BeerMaster].self, from: data) {
            masterBeers = locals
        }
        // Firestore extras
        Firestore.firestore()
            .collection("beerMaster")
            .getDocuments { snap, _ in
                guard let docs = snap?.documents else { return }
                let extras = docs.compactMap { doc -> BeerMaster? in
                    let d = doc.data()
                    guard let n = d["name"] as? String,
                          let a = d["assetName"] as? String else { return nil }
                    let p = d["photoURL"] as? String
                    return BeerMaster(id: doc.documentID, name: n, assetName: a, photoURL: p)
                }
                masterBeers.append(contentsOf: extras)
            }
    }

    private func filterBeers() {
        let q = beerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            filteredBeers = []
            showAddNew    = false
        } else {
            filteredBeers = masterBeers
                .filter { $0.name.lowercased().hasPrefix(q.lowercased()) }
                .sorted { $0.name < $1.name }
            showAddNew = filteredBeers.isEmpty
        }
    }

    private func select(_ beer: BeerMaster) {
        beerName      = beer.name
        filteredBeers = []
        showAddNew    = false
    }

    private func addNewBeer() {
        let name = beerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let db   = Firestore.firestore().collection("beerMaster")
        var ref: DocumentReference?
        ref = db.addDocument(data: ["name": name, "assetName": name]) { err in
            guard err == nil, let docID = ref?.documentID else { return }
            // upload photo if any
            if let uiImg = selectedImage,
               let jpeg = uiImg.jpegData(compressionQuality: 0.8) {
                let storageRef = Storage.storage().reference()
                    .child("beer_photos/\(docID).jpg")
                storageRef.putData(jpeg, metadata: nil) { _, error in
                    guard error == nil else { return }
                    storageRef.downloadURL { url, _ in
                        if let urlStr = url?.absoluteString {
                            db.document(docID).updateData(["photoURL": urlStr])
                        }
                    }
                }
            }
            let newBeer = BeerMaster(id: docID, name: name, assetName: name, photoURL: nil)
            masterBeers.append(newBeer)
            select(newBeer)
        }
    }

    private func saveBeer() {
        let entry = BeerEntry(context: viewContext)
        entry.name     = beerName
        entry.type     = type
        entry.date     = Date()
        entry.location = location == "Home"
            ? "Home"
            : "\(location): \(friendOrBar)"
        do {
            try viewContext.save()
        } catch {
            print("Core Data save error:", error)
        }
        if let uid = Auth.auth().currentUser?.uid {
            let data: [String:Any] = [
                "name":     entry.name     ?? "",
                "type":     entry.type     ?? "",
                "location": entry.location ?? "",
                "date":     Timestamp(date: entry.date ?? Date())
            ]
            Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("beers")
                .addDocument(data: data)
        }
        beerName      = ""
        selectedImage = nil
        friendOrBar   = ""
    }
}
