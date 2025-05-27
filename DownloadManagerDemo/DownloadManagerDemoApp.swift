//
//  DownloadManagerDemoApp.swift
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 26/05/25.
//

// MARK: - Demo App
import SwiftUI
import SwiftData
import DownloadManager
import Combine

// MARK: - Main App
@main
struct DownloadManagerDemoApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([Course.self, Module.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
