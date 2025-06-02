//
//  OnlineModuleManager.swift (Updated)
//  DownloadManagerDemo
//
//  Fixed version with centralized download management and deterministic IDs
//

import SwiftUI
import DownloadManager
import Combine
import SwiftData
import CryptoKit

// MARK: - Online Module Manager (Fixed)
@MainActor
class OnlineModuleManager: ObservableObject {
    // MARK: - Published Properties
    @Published var downloadState: DownloadState = .notDownloaded
    @Published var downloadProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var isInitialized: Bool = false
    
    // MARK: - Private Properties
    private var module: Module?
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    // Reference to centralized manager
    private let centralManager = CentralizedDownloadManager.shared
    
    // MARK: - Initialization
    func setup(modelContext: ModelContext, url: String, courseId: UUID?, title: String?, moduleType: ModuleType) {
        self.modelContext = modelContext
        
        Task {
            do {
                // Initialize central manager if needed
                await centralManager.initialize(modelContext: modelContext)
                
                // Create module with deterministic ID
                await createModuleFromURL(url: url, courseId: courseId, title: title, moduleType: moduleType)
                
                // Check if module already exists in storage
                await checkExistingModule()
                
                // Setup state observers
                setupStateObservers()
                
                // Update initial state
                await updateStateFromCentralManager()
                
                isInitialized = true
                print("✅ OnlineModuleManager setup completed for: \(title ?? url)")
                
            } catch {
                errorMessage = "Setup failed: \(error.localizedDescription)"
                print("❌ OnlineModuleManager setup failed: \(error)")
            }
        }
    }
    
   
    
    // MARK: - Check Existing Module
    private func checkExistingModule() async {
        guard let moduleId = module?.id,
              let storage = try? SwiftDataDownloadStorage(modelContainer: modelContext?.container ?? ModelContainer.init(for: Course.self, Module.self)) else {
            return
        }
        
        do {
            if let existingModule = try await storage.fetchItem(by: moduleId) {
                // Update our module with existing data
                module = existingModule
                print("📋 Found existing module: \(existingModule.title)")
            }
        } catch {
            print("⚠️ Could not check for existing module: \(error)")
        }
    }
    
    // MARK: - State Observers
    private func setupStateObservers() {
        guard let moduleId = module?.id else { return }
        
        // Observe state changes from central manager
        centralManager.$downloadStates
            .receive(on: DispatchQueue.main)
            .map { states in
                states[moduleId] ?? .notDownloaded
            }
            .removeDuplicates()
            .sink { [weak self] newState in
                self?.downloadState = newState
                self?.clearErrorIfNeeded(for: newState)
            }
            .store(in: &cancellables)
        
        // Observe progress changes
        centralManager.$downloadProgress
            .receive(on: DispatchQueue.main)
            .map { progress in
                progress[moduleId] ?? 0.0
            }
            .sink { [weak self] newProgress in
                self?.downloadProgress = newProgress
            }
            .store(in: &cancellables)
    }
    
    // MARK: - State Updates
    private func updateStateFromCentralManager() async {
        guard let moduleId = module?.id else { return }
        
        downloadState = centralManager.getDownloadState(for: moduleId)
        downloadProgress = centralManager.getDownloadProgress(for: moduleId)
        
        print("🔄 Updated state for module \(moduleId): \(downloadState), progress: \(downloadProgress)")
    }
    
    // MARK: - Download Operations
    func download() async {
        guard let module = module else {
            errorMessage = "Module not initialized"
            return
        }
        
        clearError()
        
        do {
            await centralManager.downloadModule(module) {
                self.createDefaultParentCourse()
            }
            print("🚀 Started download for: \(module.title)")
        } catch {
            errorMessage = "Download failed: \(error.localizedDescription)"
            print("❌ Download failed for \(module.title): \(error)")
        }
    }
    
    func pause() async {
        guard let moduleId = module?.id else {
            errorMessage = "Module not initialized"
            return
        }
        
        clearError()
        
        do {
            await centralManager.pauseDownload(itemId: moduleId)
            print("⏸️ Paused download for module: \(moduleId)")
        } catch {
            errorMessage = "Pause failed: \(error.localizedDescription)"
            print("❌ Pause failed for module \(moduleId): \(error)")
        }
    }
    
    func resume() async {
        guard let moduleId = module?.id else {
            errorMessage = "Module not initialized"
            return
        }
        
        clearError()
        
        do {
            await centralManager.resumeDownload(itemId: moduleId)
            print("▶️ Resumed download for module: \(moduleId)")
        } catch {
            errorMessage = "Resume failed: \(error.localizedDescription)"
            print("❌ Resume failed for module \(moduleId): \(error)")
        }
    }
    
    func delete() async {
        guard let moduleId = module?.id else {
            errorMessage = "Module not initialized"
            return
        }
        
        clearError()
        
        do {
            await centralManager.deleteDownload(itemId: moduleId)
            print("🗑️ Deleted download for module: \(moduleId)")
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
            print("❌ Delete failed for module \(moduleId): \(error)")
        }
    }
    
    func cancel() async {
        guard let moduleId = module?.id else {
            errorMessage = "Module not initialized"
            return
        }
        
        clearError()
        
        do {
            await centralManager.cancelDownload(itemId: moduleId)
            print("🚫 Cancelled download for module: \(moduleId)")
        } catch {
            errorMessage = "Cancel failed: \(error.localizedDescription)"
            print("❌ Cancel failed for module \(moduleId): \(error)")
        }
    }
    
    // MARK: - Helper Methods
    func getPlayableURL() -> URL? {
        guard let module = module else { return nil }
        
        // Return local URL if downloaded, otherwise online URL
        if downloadState == .downloaded, let localURL = module.localFileURL {
            return localURL
        } else {
            return module.downloadURL
        }
    }
    
    func getModuleInfo() -> (title: String, url: String, type: ModuleType)? {
        guard let module = module else { return nil }
        return (module.title, module.downloadURL.absoluteString, module.downloadType)
    }
    
    func isDownloaded() -> Bool {
        return downloadState == .downloaded
    }
    
    func isDownloading() -> Bool {
        return [.downloading, .queued].contains(downloadState)
    }
    
    func canRetry() -> Bool {
        return downloadState == .failed
    }
    
    // MARK: - Error Management
    private func clearError() {
        errorMessage = nil
    }
    
    private func clearErrorIfNeeded(for state: DownloadState) {
        if state != .failed {
            errorMessage = nil
        }
    }
    
   
    
    private func generateDeterministicIntID(from input: String) -> Int {
        // Generate a deterministic integer ID from URL
        return abs(input.hashValue % 100000)
    }
    
    private func extractTitleFromURL(_ url: String) -> String {
        // Extract a meaningful title from URL
        guard let urlObject = URL(string: url) else { return "Online Module" }
        
        let filename = urlObject.lastPathComponent
        let nameWithoutExtension = (filename as NSString).deletingPathExtension
        
        // Clean up the name
        let cleanName = nameWithoutExtension
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
        
        return cleanName.isEmpty ? "Online Module" : cleanName
    }
    
    private func createDefaultParentCourse() -> Course {
        return Course(
            courseId: generateDeterministicIntID(from: "default-online-course"),
            courseType: "Online",
            courseCode: "WEB001",
            courseTitle: "Web Resources",
            numberOfModules: 1,
            courseFee: 0.0,
            description: "Collection of online web resources and modules",
            adminName: "System",
            courseRating: 0.0
        )
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
        print("🧹 OnlineModuleManager deallocated")
    }
}

// MARK: - State Computed Properties
extension OnlineModuleManager {
    var stateDescription: String {
        switch downloadState {
        case .notDownloaded:
            return "Ready to download"
        case .queued:
            return "Queued for download"
        case .downloading:
            return "Downloading... \(Int(downloadProgress * 100))%"
        case .paused:
            return "Download paused"
        case .downloaded:
            return "Downloaded"
        case .failed:
            return "Download failed"
        case .cancelling:
            return "Cancelling..."
        }
    }
    
    var progressDescription: String {
        guard downloadState == .downloading else { return "" }
        return "\(Int(downloadProgress * 100))%"
    }
    
    var canDownload: Bool {
        return [.notDownloaded, .failed].contains(downloadState) && isInitialized
    }
    
    var canPause: Bool {
        return downloadState == .downloading
    }
    
    var canResume: Bool {
        return downloadState == .paused
    }
    
    var canPlay: Bool {
        return downloadState == .downloaded
    }
    
    var canDelete: Bool {
        return downloadState == .downloaded
    }
    
    var canCancel: Bool {
        return [.downloading, .queued, .paused].contains(downloadState)
    }
}

// MARK: - Debug Extensions
extension OnlineModuleManager {
    func printDebugInfo() {
        print("""
        📊 OnlineModuleManager Debug Info:
        - Initialized: \(isInitialized)
        - Module ID: \(module?.id.uuidString ?? "None")
        - Download State: \(downloadState)
        - Progress: \(downloadProgress)
        - Error: \(errorMessage ?? "None")
        - Module Title: \(module?.title ?? "None")
        - Module URL: \(module?.downloadURL.absoluteString ?? "None")
        """)
    }
}

extension OnlineModuleManager {
    
    /// Generates a deterministic UUID based on URL to prevent duplicates
    private func generateDeterministicUUID(from url: String) -> UUID {
        // Create a consistent hash from the URL
        let inputData = Data(url.utf8)
        let hash = SHA256.hash(data: inputData)
        
        // Convert first 16 bytes of hash to UUID
        let hashBytes = Array(hash)[0..<16]
        let uuidString = hashBytes.map { String(format: "%02x", $0) }.joined()
        
        // Format as UUID string: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        let formattedUUID = String(format: "%@-%@-%@-%@-%@",
                                  String(uuidString.prefix(8)),
                                  String(uuidString.dropFirst(8).prefix(4)),
                                  String(uuidString.dropFirst(12).prefix(4)),
                                  String(uuidString.dropFirst(16).prefix(4)),
                                  String(uuidString.suffix(12)))
        
        return UUID(uuidString: formattedUUID) ?? UUID()
    }
    
    /// Updated module creation with deterministic IDs
    private func createModuleFromURL(url: String, courseId: UUID?, title: String?, moduleType: ModuleType) async {
        guard let downloadURL = URL(string: url) else {
            print("❌ Invalid URL: \(url)")
            return
        }
        
        // Generate deterministic UUID to prevent duplicates
        let moduleUUID = generateDeterministicUUID(from: url)
        
        module = Module(
            id: moduleUUID,
            moduleId: Int(abs(url.hashValue) % 100000), // Deterministic int ID too
            moduleName: title ?? "Online Module",
            path: url,
            moduleType: moduleType,
            description: "Module from URL: \(url)",
            duration: 0,
            sequenceNo: 1,
            downloadURL: downloadURL,
            parentModelId: courseId ?? generateDeterministicUUID(from: "default-course")
        )
    }
}
