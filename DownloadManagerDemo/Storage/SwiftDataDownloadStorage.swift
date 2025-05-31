//
//  SwiftDataDownloadStorage.swift
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 27/05/25.
//


// MARK: - Demo App Models
import Foundation
import SwiftData
import DownloadManager


// MARK: - SwiftData Storage Implementation
@MainActor
final class SwiftDataDownloadStorage: DownloadStorageProtocol,  @unchecked Sendable  {
    typealias Model = Course
    typealias Item = Module
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }
    
    // Alternative init for standalone usage
    init() throws {
        let schema = Schema([Course.self, Module.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        self.modelContext = modelContainer.mainContext
    }
    
    func saveModel(_ model: Course) async throws {
        // Insert all modules first
        for module in model.modules {
            modelContext.insert(module)
        }
        
        // Then insert the course
        modelContext.insert(model)
        try modelContext.save()
    }
    
    func fetchModel(by id: UUID) async throws -> Course? {
        let descriptor = FetchDescriptor<Course>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func fetchAllModels() async throws -> [Course] {
        let descriptor = FetchDescriptor<Course>()
        return try modelContext.fetch(descriptor)
    }
    
    func deleteModel(_ model: Course) async throws {
        // Delete all associated modules first
        for module in model.modules {
            modelContext.delete(module)
        }
        modelContext.delete(model)
        try modelContext.save()
    }
    
    func saveItem(_ item: Module) async throws {
        // Check if item already exists
       
            modelContext.insert(item)
            try modelContext.save()
        
    }
    
    func fetchItem(by id: UUID) async throws -> Module? {
        let descriptor = FetchDescriptor<Module>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func fetchItems(for modelId: UUID) async throws -> [Module] {
        let descriptor = FetchDescriptor<Module>(
            predicate: #Predicate { $0.parentModelId == modelId }
        )
        return try modelContext.fetch(descriptor)
    }
    
    func updateItem(_ item: Module) async throws {
        // SwiftData automatically tracks changes
        // Just ensure the item is registered with the context
        if let existingItem = modelContext.model(for: item.id) as? Module {
            existingItem.downloadState = item.downloadState
            existingItem.downloadProgress = item.downloadProgress
            existingItem.localFileURL = item.localFileURL
            existingItem.fileSize = item.fileSize
        }
        try modelContext.save()
    }
    
    func saveDownloadRecord(itemId: UUID, state: DownloadState, progress: Double, localURL: URL?, fileSize: Int64?) async throws {
        if let item = try await fetchItem(by: itemId) {
            item.downloadState = state
            item.downloadProgress = progress
            item.localFileURL = localURL
            item.fileSize = fileSize
            try modelContext.save()
        }
    }
    
    func fetchDownloadRecord(itemId: UUID) async throws -> (state: DownloadState, progress: Double, localURL: URL?, fileSize: Int64?)? {
        if let item = try await fetchItem(by: itemId) {
            return (item.downloadState, item.downloadProgress, item.localFileURL, item.fileSize)
        }
        return nil
    }
    
    func deleteDownloadRecord(itemId: UUID) async throws {
        if let item = try await fetchItem(by: itemId) {
            item.downloadState = .notDownloaded
            item.downloadProgress = 0.0
            item.localFileURL = nil
            item.fileSize = nil
            try modelContext.save()
        }
    }
    
    func clearAllData() async throws {
        try modelContext.delete(model: Course.self)
        try modelContext.delete(model: Module.self)
        try modelContext.save()
    }
}
