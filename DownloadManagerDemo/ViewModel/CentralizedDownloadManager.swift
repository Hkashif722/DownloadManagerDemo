//
//  CentralizedDownloadManager.swift
//  DownloadManagerDemo
//
//  Centralized download management to fix tab inconsistencies
//

import SwiftUI
import DownloadManager
import Combine
import SwiftData

// MARK: - Singleton Download Manager
@MainActor
class CentralizedDownloadManager: ObservableObject {
    static let shared = CentralizedDownloadManager()
    
    private var downloadManager: DownloadManager<Course, SwiftDataDownloadStorage>?
    private var storage: SwiftDataDownloadStorage?
    
    @Published var downloadStates: [UUID: DownloadState] = [:]
    @Published var downloadProgress: [UUID: Double] = [:]
    @Published var activeDownloadsCount: Int = 0
    
    private var isInitialized = false
    
    private init() {}
    
    func initialize(modelContext: ModelContext) async {
        guard !isInitialized else { return }
        
        do {
            let storage = SwiftDataDownloadStorage(modelContainer: modelContext.container)
            self.storage = storage
            
            let configuration = DownloadConfiguration(
                maxConcurrentDownloads: 3,
                allowsCellularAccess: true
            )
            
            downloadManager = try DownloadManagerBuilder<Course, SwiftDataDownloadStorage>()
                .with(configuration: configuration)
                .with(storage: storage)
                .withStrategy(DocumentDownloadStrategy(), for: .document)
                .withStrategy(VideoDownloadStrategy(), for: .video)
                .withStrategy(YouTubeDownloadStrategy(), for: .youtube)
                .withStrategy(SCORMDownloadStrategy(), for: .scorm)
                .build()
            
            // Subscribe to state changes
            downloadManager?.$downloadStates
                .receive(on: DispatchQueue.main)
                .assign(to: &$downloadStates)
            
            downloadManager?.$downloadProgress
                .receive(on: DispatchQueue.main)
                .assign(to: &$downloadProgress)
            
            downloadManager?.$activeDownloadsCount
                .receive(on: DispatchQueue.main)
                .assign(to: &$activeDownloadsCount)
            
            // Initialize pending downloads
            await downloadManager?.initializePendingTasksFromStorage()
            
            isInitialized = true
            print("✅ CentralizedDownloadManager initialized successfully")
            
        } catch {
            print("❌ Failed to setup centralized download manager: \(error)")
        }
    }
    
    // MARK: - Download Operations
    func downloadModule(_ module: Module, parentCourseFactory: (() -> Course)? = nil) async {
        guard let downloadManager = downloadManager else {
            print("❌ Download manager not initialized")
            return
        }
        
        do {
            try await downloadManager.downloadItem(module) {
                return parentCourseFactory?() ?? self.createDefaultCourse(for: module)
            }
        } catch {
            print("❌ Failed to download module: \(error)")
        }
    }
    
    func downloadCourse(_ course: Course) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.downloadModel(course)
        } catch {
            print("❌ Failed to download course: \(error)")
        }
    }
    
    func pauseDownload(itemId: UUID) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.pauseDownload(itemId: itemId)
        } catch {
            print("❌ Failed to pause download: \(error)")
        }
    }
    
    func resumeDownload(itemId: UUID) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.resumeDownload(itemId: itemId)
        } catch {
            print("❌ Failed to resume download: \(error)")
        }
    }
    
    func cancelDownload(itemId: UUID) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.cancelDownload(itemId: itemId)
        } catch {
            print("❌ Failed to cancel download: \(error)")
        }
    }
    
    func deleteDownload(itemId: UUID) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.deleteDownload(itemId: itemId)
        } catch {
            print("❌ Failed to delete download: \(error)")
        }
    }
    
    func clearAllDownloads() async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.clearAllDownloadsAndData()
        } catch {
            print("❌ Failed to clear all downloads: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    func getDownloadState(for moduleId: UUID) -> DownloadState {
        return downloadStates[moduleId] ?? .notDownloaded
    }
    
    func getDownloadProgress(for moduleId: UUID) -> Double {
        return downloadProgress[moduleId] ?? 0.0
    }
    
    func isModuleDownloaded(_ moduleId: UUID) -> Bool {
        return downloadStates[moduleId] == .downloaded
    }
    
    private func createDefaultCourse(for module: Module) -> Course {
        return Course(
            courseId: Int.random(in: 10000...99999),
            courseType: "Online",
            courseCode: "WEB001",
            courseTitle: "Web Resources",
            numberOfModules: 1,
            courseFee: 0.0,
            description: "Online web resources and modules",
            adminName: "System",
            courseRating: 0.0
        )
    }
}
