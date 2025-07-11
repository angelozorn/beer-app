//
//  Beer_Tracker_AppApp.swift
//  Beer-Tracker-App
//
//  Created by Angelo Zorn on 6/16/25.
//

import SwiftUI
import Firebase

@main
struct Beer_Tracker_AppApp: App {
    // 1. Grab your PersistenceController
    let persistenceController = PersistenceController.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 2. Inject the viewContext into the environment
                .environment(\.managedObjectContext,
                             persistenceController.container.viewContext)
        }
    }
}
