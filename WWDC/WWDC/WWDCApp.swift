//
//  WWDCApp.swift
//  WWDC
//
//  Created by Jihaha kim on 2024/02/18.
//

import SwiftUI

@main
struct WWDCApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
