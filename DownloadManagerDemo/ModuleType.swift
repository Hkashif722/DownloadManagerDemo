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

// MARK: - Course Model
@Model
final class Course: DownloadableModel {
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
    
    @Relationship(deleteRule: .cascade, inverse: \Module.parentModelId)
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

// MARK: - SwiftData Storage Implementation
actor SwiftDataDownloadStorage: DownloadStorageProtocol {
    typealias Model = Course
    typealias Item = Module
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() throws {
        let schema = Schema([Course.self, Module.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        self.modelContext = ModelContext(modelContainer)
        self.modelContext.autosaveEnabled = true
    }
    
    func saveModel(_ model: Course) async throws {
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
        modelContext.delete(model)
        try modelContext.save()
    }
    
    func saveItem(_ item: Module) async throws {
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