//
//  OVERENDApp.swift
//  OVEREND
//
//  Created by Lawliet on 2025/12/28.
//

import SwiftUI
import CoreData

@main
struct OVERENDApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
