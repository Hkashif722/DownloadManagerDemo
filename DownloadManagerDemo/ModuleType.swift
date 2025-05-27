// MARK: - Demo App Models
import Foundation
import SwiftData
import DownloadManager

// MARK: - Module Type
enum ModuleType: String, CaseIterable, Codable, DownloadTypeProtocol {
    case document = "Document"
    case video = "Video"
    case audio = "Audio"
    case youtube = "YouTube"
    case scorm = "SCORM"
    
    var fileExtension: String {
        switch self {
        case .document: return "pdf" // Default to PDF, but can be dynamic based on mimeType
        case .video: return "mp4"
        case .audio: return "mp3"
        case .youtube: return "txt" // Store YouTube ID as text file
        case .scorm: return "zip"
        }
    }
    
    var mimeType: String? {
        switch self {
        case .document: return "application/pdf"
        case .video: return "video/mp4"
        case .audio: return "audio/mpeg"
        case .youtube: return "text/plain"
        case .scorm: return "application/zip"
        }
    }
    
    var requiresSpecialHandling: Bool {
        switch self {
        case .youtube, .scorm: return true
        default: return false
        }
    }
}

// MARK: - Module Model
@Model
final class Module: DownloadableItem {
    typealias DownloadType = ModuleType
    
    @Attribute(.unique) var id: UUID
    var moduleId: Int
    var title: String
    var moduleDescription: String
    var mimeType: String?
    var path: String
    var zipPath: String?
    var moduleTypeRaw: String
    var duration: Double
    var youtubeVideoId: String?
    var isSecuredContent: Bool
    var downloadURL: URL
    var localFileURL: URL?
    var downloadStateRaw: String
    var downloadProgress: Double
    var fileSize: Int64?
    var parentModelId: UUID?
    
    var downloadType: ModuleType {
        ModuleType(rawValue: moduleTypeRaw) ?? .document
    }
    
    var downloadState: DownloadState {
        get { DownloadState(rawValue: downloadStateRaw) ?? .notDownloaded }
        set { downloadStateRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        moduleId: Int,
        title: String,
        description: String,
        mimeType: String? = nil,
        path: String,
        zipPath: String? = nil,
        moduleType: ModuleType,
        duration: Double,
        youtubeVideoId: String? = nil,
        isSecuredContent: Bool = false,
        downloadURL: URL,
        parentModelId: UUID? = nil
    ) {
        self.id = id
        self.moduleId = moduleId
        self.title = title
        self.moduleDescription = description
        self.mimeType = mimeType
        self.path = path
        self.zipPath = zipPath
        self.moduleTypeRaw = moduleType.rawValue
        self.duration = duration
        self.youtubeVideoId = youtubeVideoId
        self.isSecuredContent = isSecuredContent
        self.downloadURL = downloadURL
        self.localFileURL = nil
        self.downloadStateRaw = DownloadState.notDownloaded.rawValue
        self.downloadProgress = 0.0
        self.fileSize = nil
        self.parentModelId = parentModelId
    }
}

// MARK: - Module Codable Conformance
extension Module: Codable {
    enum CodingKeys: String, CodingKey {
        case id, moduleId, title, moduleDescription, mimeType, path, zipPath
        case moduleTypeRaw, duration, youtubeVideoId, isSecuredContent
        case downloadURL, localFileURL, downloadStateRaw, downloadProgress
        case fileSize, parentModelId
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            moduleId: try container.decode(Int.self, forKey: .moduleId),
            title: try container.decode(String.self, forKey: .title),
            description: try container.decode(String.self, forKey: .moduleDescription),
            mimeType: try container.decodeIfPresent(String.self, forKey: .mimeType),
            path: try container.decode(String.self, forKey: .path),
            zipPath: try container.decodeIfPresent(String.self, forKey: .zipPath),
            moduleType: ModuleType(rawValue: try container.decode(String.self, forKey: .moduleTypeRaw)) ?? .document,
            duration: try container.decode(Double.self, forKey: .duration),
            youtubeVideoId: try container.decodeIfPresent(String.self, forKey: .youtubeVideoId),
            isSecuredContent: try container.decode(Bool.self, forKey: .isSecuredContent),
            downloadURL: try container.decode(URL.self, forKey: .downloadURL),
            parentModelId: try container.decodeIfPresent(UUID.self, forKey: .parentModelId)
        )
        
        // Set properties that aren't part of init
        self.localFileURL = try container.decodeIfPresent(URL.self, forKey: .localFileURL)
        self.downloadStateRaw = try container.decode(String.self, forKey: .downloadStateRaw)
        self.downloadProgress = try container.decode(Double.self, forKey: .downloadProgress)
        self.fileSize = try container.decodeIfPresent(Int64.self, forKey: .fileSize)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(moduleId, forKey: .moduleId)
        try container.encode(title, forKey: .title)
        try container.encode(moduleDescription, forKey: .moduleDescription)
        try container.encodeIfPresent(mimeType, forKey: .mimeType)
        try container.encode(path, forKey: .path)
        try container.encodeIfPresent(zipPath, forKey: .zipPath)
        try container.encode(moduleTypeRaw, forKey: .moduleTypeRaw)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(youtubeVideoId, forKey: .youtubeVideoId)
        try container.encode(isSecuredContent, forKey: .isSecuredContent)
        try container.encode(downloadURL, forKey: .downloadURL)
        try container.encodeIfPresent(localFileURL, forKey: .localFileURL)
        try container.encode(downloadStateRaw, forKey: .downloadStateRaw)
        try container.encode(downloadProgress, forKey: .downloadProgress)
        try container.encodeIfPresent(fileSize, forKey: .fileSize)
        try container.encodeIfPresent(parentModelId, forKey: .parentModelId)
    }
}

// MARK: - Course Model
@Model
final class Course: DownloadableModel, @unchecked Sendable  {
    typealias ItemType = Module
    
    @Attribute(.unique) var id: UUID
    var courseId: Int
    var title: String
    var courseType: String
    var courseCode: String
    var courseDescription: String
    var thumbnailPath: String?
    var numberOfModules: Int
    var courseFee: Double
    var adminName: String
    var courseRating: Double
    var metadataJSON: String? // Store metadata as JSON string
    
    // Use a simple array without inverse relationship to avoid complexity
    var modules: [Module] = []
    
    var items: [Module] {
        get { modules }
        set { modules = newValue }
    }
    
    var metadata: [String: String]? {
        get {
            guard let json = metadataJSON,
                  let data = json.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
                return nil
            }
            return dict
        }
        set {
            guard let dict = newValue else {
                metadataJSON = nil
                return
            }
            if let data = try? JSONSerialization.data(withJSONObject: dict),
               let json = String(data: data, encoding: .utf8) {
                metadataJSON = json
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        courseId: Int,
        title: String,
        courseType: String,
        courseCode: String,
        description: String,
        thumbnailPath: String? = nil,
        numberOfModules: Int,
        courseFee: Double,
        adminName: String,
        courseRating: Double
    ) {
        self.id = id
        self.courseId = courseId
        self.title = title
        self.courseType = courseType
        self.courseCode = courseCode
        self.courseDescription = description
        self.thumbnailPath = thumbnailPath
        self.numberOfModules = numberOfModules
        self.courseFee = courseFee
        self.adminName = adminName
        self.courseRating = courseRating
    }
}

// MARK: - Course Codable Conformance
extension Course: Codable {
    enum CodingKeys: String, CodingKey {
        case id, courseId, title, courseType, courseCode, courseDescription
        case thumbnailPath, numberOfModules, courseFee, adminName, courseRating
        case metadataJSON, modules
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            courseId: try container.decode(Int.self, forKey: .courseId),
            title: try container.decode(String.self, forKey: .title),
            courseType: try container.decode(String.self, forKey: .courseType),
            courseCode: try container.decode(String.self, forKey: .courseCode),
            description: try container.decode(String.self, forKey: .courseDescription),
            thumbnailPath: try container.decodeIfPresent(String.self, forKey: .thumbnailPath),
            numberOfModules: try container.decode(Int.self, forKey: .numberOfModules),
            courseFee: try container.decode(Double.self, forKey: .courseFee),
            adminName: try container.decode(String.self, forKey: .adminName),
            courseRating: try container.decode(Double.self, forKey: .courseRating)
        )
        
        // Set properties that aren't part of init
        self.metadataJSON = try container.decodeIfPresent(String.self, forKey: .metadataJSON)
        self.modules = try container.decode([Module].self, forKey: .modules)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(courseId, forKey: .courseId)
        try container.encode(title, forKey: .title)
        try container.encode(courseType, forKey: .courseType)
        try container.encode(courseCode, forKey: .courseCode)
        try container.encode(courseDescription, forKey: .courseDescription)
        try container.encodeIfPresent(thumbnailPath, forKey: .thumbnailPath)
        try container.encode(numberOfModules, forKey: .numberOfModules)
        try container.encode(courseFee, forKey: .courseFee)
        try container.encode(adminName, forKey: .adminName)
        try container.encode(courseRating, forKey: .courseRating)
        try container.encodeIfPresent(metadataJSON, forKey: .metadataJSON)
        try container.encode(modules, forKey: .modules)
    }
}

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

// MARK: - Download Strategies
struct DocumentDownloadStrategy: DownloadStrategy {
    typealias Item = Module
    
    func prepareDownload(for item: Module, resumeData: Data?) async throws -> DownloadPreparation {
        // In a real app, you might need to decrypt the path or add auth headers
        let headers = ["Authorization": "Bearer YOUR_TOKEN"]
        return DownloadPreparation(url: item.downloadURL, headers: headers, resumeData: resumeData)
    }
    
    func processDownloadedFile(at temporaryURL: URL, for item: Module) async throws -> URL {
        // No special processing for documents
        return temporaryURL
    }
    
    func validateDownload(at fileURL: URL, for item: Module) async throws -> Bool {
        // Check if file exists and has content
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        return fileSize > 0
    }
}

struct VideoDownloadStrategy: DownloadStrategy {
    typealias Item = Module
    
    func prepareDownload(for item: Module, resumeData: Data?) async throws -> DownloadPreparation {
        let headers = ["Authorization": "Bearer YOUR_TOKEN"]
        return DownloadPreparation(url: item.downloadURL, headers: headers, resumeData: resumeData)
    }
    
    func processDownloadedFile(at temporaryURL: URL, for item: Module) async throws -> URL {
        // Could transcode or optimize video here
        return temporaryURL
    }
    
    func validateDownload(at fileURL: URL, for item: Module) async throws -> Bool {
        // Validate video file
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        return fileSize > 1000 // At least 1KB
    }
}

struct YouTubeDownloadStrategy: DownloadStrategy {
    typealias Item = Module
    
    func prepareDownload(for item: Module, resumeData: Data?) async throws -> DownloadPreparation {
        // For YouTube, we'll just save the video ID as a text file
        guard let videoId = item.youtubeVideoId else {
            throw DownloadError.invalidURL("Missing YouTube video ID")
        }
        
        // Create a temporary file with the video ID
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("\(item.id).txt")
        try videoId.write(to: tempFile, atomically: true, encoding: .utf8)
        
        // Return the local file URL as the download URL
        return DownloadPreparation(url: tempFile, headers: nil, resumeData: nil)
    }
    
    func processDownloadedFile(at temporaryURL: URL, for item: Module) async throws -> URL {
        return temporaryURL
    }
    
    func validateDownload(at fileURL: URL, for item: Module) async throws -> Bool {
        // Check if we can read the YouTube ID
        let videoId = try String(contentsOf: fileURL, encoding: .utf8)
        return !videoId.isEmpty
    }
}

struct SCORMDownloadStrategy: DownloadStrategy {
    typealias Item = Module
    
    func prepareDownload(for item: Module, resumeData: Data?) async throws -> DownloadPreparation {
        // Use zipPath if available, otherwise use regular path
        let downloadURL = item.zipPath != nil ? item.downloadURL : item.downloadURL
        let headers = ["Authorization": "Bearer YOUR_TOKEN"]
        return DownloadPreparation(url: downloadURL, headers: headers, resumeData: resumeData)
    }
    
    func processDownloadedFile(at temporaryURL: URL, for item: Module) async throws -> URL {
        // In a real app, you might unzip the SCORM package here
        // For now, we'll just keep it as a zip
        return temporaryURL
    }
    
    func validateDownload(at fileURL: URL, for item: Module) async throws -> Bool {
        // Validate it's a valid zip file
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        return fileSize > 100 // At least 100 bytes
    }
}

// MARK: - API Response Models
struct CourseResponse: Codable {
    let courseId: Int
    let courseType: String
    let courseCode: String
    let courseTitle: String
    let numberofModules: Int
    let courseFee: Double
    let description: String
    let adminName: String
    let courseRating: Double
    let thumbnailPath: String?
    let modules: [ModuleResponse]
}

struct ModuleResponse: Codable {
    let moduleId: Int
    let moduleName: String
    let mimeType: String?
    let path: String
    let zipPath: String?
    let moduleType: String
    let description: String
    let duration: Double
    let youtubeVideoId: String?
    let isSecuredContent: Bool
}

// MARK: - Course Parser
class CourseParser {
    static func parseCourse(from response: CourseResponse, baseURL: String) -> Course {
        let course = Course(
            courseId: response.courseId,
            title: response.courseTitle,
            courseType: response.courseType,
            courseCode: response.courseCode,
            description: response.description,
            thumbnailPath: response.thumbnailPath,
            numberOfModules: response.numberofModules,
            courseFee: response.courseFee,
            adminName: response.adminName,
            courseRating: response.courseRating
        )
        
        // Parse modules
        course.modules = response.modules.map { moduleResponse in
            // Construct download URL - in real app, this would be properly decrypted/constructed
            let downloadURL = URL(string: "\(baseURL)/download/\(moduleResponse.path)") ?? URL(string: "https://example.com")!
            
            return Module(
                moduleId: moduleResponse.moduleId,
                title: moduleResponse.moduleName,
                description: moduleResponse.description,
                mimeType: moduleResponse.mimeType,
                path: moduleResponse.path,
                zipPath: moduleResponse.zipPath,
                moduleType: ModuleType(rawValue: moduleResponse.moduleType) ?? .document,
                duration: moduleResponse.duration,
                youtubeVideoId: moduleResponse.youtubeVideoId,
                isSecuredContent: moduleResponse.isSecuredContent,
                downloadURL: downloadURL,
                parentModelId: course.id
            )
        }
        
        return course
    }
}
