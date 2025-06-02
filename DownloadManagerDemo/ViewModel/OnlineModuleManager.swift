//
//  OnlineModuleManager.swift
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 02/06/25.
//

import SwiftUI
import DownloadManager
import Combine
import SwiftData

// MARK: - Online Module Manager
@MainActor
class OnlineModuleManager: ObservableObject {
    @Published var downloadState: DownloadState = .notDownloaded
    @Published var downloadProgress: Double = 0.0
    
    private var module: Module?
    private var downloadManager: DownloadManager<Course, SwiftDataDownloadStorage>?
    private var storage: SwiftDataDownloadStorage?
    private var cancellables = Set<AnyCancellable>()
    
    func setup(modelContext: ModelContext,url: String, courseId: UUID?, title: String?, moduleType: ModuleType) {
        Task {
            await initializeDownloadManager(modelContext: modelContext)
            await createModuleFromURL(url: url, courseId: courseId, title: title, moduleType: moduleType)
            await updateState()
        }
    }
    
    private func initializeDownloadManager(modelContext: ModelContext) async {
        do {
            // Create storage
            self.storage = SwiftDataDownloadStorage(modelContainer: modelContext.container)
            
            guard let storage = self.storage else { return }
            
            // Create configuration
            let configuration = DownloadConfiguration(
                maxConcurrentDownloads: 3,
                allowsCellularAccess: true
            )
            
            // Build download manager
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
                .sink { [weak self] states in
                    if let moduleId = self?.module?.id {
                        self?.downloadState = states[moduleId] ?? .notDownloaded
                    }
                }
                .store(in: &cancellables)
            
            downloadManager?.$downloadProgress
                .receive(on: DispatchQueue.main)
                .sink { [weak self] progress in
                    if let moduleId = self?.module?.id {
                        self?.downloadProgress = progress[moduleId] ?? 0.0
                    }
                }
                .store(in: &cancellables)
            
        } catch {
            print("Failed to initialize download manager: \(error)")
        }
    }
    
    private func createModuleFromURL(url: String, courseId: UUID?, title: String?, moduleType: ModuleType) async {
        guard let downloadURL = URL(string: url) else {
            print("Invalid URL: \(url)")
            return
        }
        
        // Create or find parent course
        let parentCourseId = courseId ?? UUID()
        
        // Create module
        module = Module(
            moduleId: Int.random(in: 1000...9999),
            moduleName: title ?? "Online Module",
            path: url,
            moduleType: moduleType,
            description: "Module from URL: \(url)",
            duration: 0,
            sequenceNo: 1,
            downloadURL: downloadURL,
            parentModelId: parentCourseId
        )
    }
    
    private func updateState() async {
        guard let module = module,
              let storage = storage else { return }
        
        // Check if module exists in storage and get its state
        if let existingModule = try? await storage.fetchItem(by: module.id) {
            downloadState = existingModule.downloadState
            downloadProgress = existingModule.downloadProgress
        }
    }
    
    func download() async {
        guard let module = module,
              let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.downloadItem(module) {
                // Create parent course if needed
                return Course(
                    courseId: Int.random(in: 1000...9999),
                    courseType: "Online",
                    courseCode: "WEB001",
                    courseTitle: "Web Resources",
                    numberOfModules: 1,
                    courseFee: 0.0,
                    description: "Online web resources",
                    adminName: "System",
                    courseRating: 0.0
                )
            }
        } catch {
            print("Download failed: \(error)")
        }
    }
    
    func pause() async {
        guard let module = module,
              let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.pauseDownload(itemId: module.id)
        } catch {
            print("Pause failed: \(error)")
        }
    }
    
    func resume() async {
        guard let module = module,
              let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.resumeDownload(itemId: module.id)
        } catch {
            print("Resume failed: \(error)")
        }
    }
    
    func delete() async {
        guard let module = module,
              let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.deleteDownload(itemId: module.id)
        } catch {
            print("Delete failed: \(error)")
        }
    }
    
    func getPlayableURL() -> URL? {
        guard let module = module else { return nil }
        
        // Return local URL if downloaded, otherwise online URL
        if downloadState == .downloaded {
            return module.localFileURL
        } else {
            return module.downloadURL
        }
    }
}
