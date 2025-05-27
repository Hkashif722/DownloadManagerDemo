//
//  ContentView.swift
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 26/05/25.
//

import SwiftUI
import SwiftData
import DownloadManager

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var courses: [Course]
    @StateObject private var viewModel = DownloadViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                if courses.isEmpty {
                    EmptyStateView(viewModel: viewModel)
                } else {
                    ForEach(courses) { course in
                        CourseRowView(course: course, viewModel: viewModel)
                    }
                    .onDelete(perform: deleteCourses)
                }
            }
            .navigationTitle("Download Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Demo") {
                        viewModel.addDemoCourse(modelContext: modelContext)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        Task {
                            await viewModel.clearAllDownloads()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .task {
            await viewModel.setupDownloadManager(modelContext: modelContext)
        }
    }
    
    private func deleteCourses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(courses[index])
            }
        }
    }
}

struct EmptyStateView: View {
    let viewModel: DownloadViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Courses Yet")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Tap 'Add Demo' to create sample courses")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
    }
}

struct CourseRowView: View {
    let course: Course
    @ObservedObject var viewModel: DownloadViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(course.modules) { module in
                ModuleRowView(module: module, viewModel: viewModel)
                    .padding(.vertical, 4)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(course.title)
                    .font(.headline)
                HStack {
                    Label("\(course.modules.count) modules", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Download all button
                    Button {
                        Task {
                            await viewModel.downloadCourse(course)
                        }
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct ModuleRowView: View {
    let module: Module
    @ObservedObject var viewModel: DownloadViewModel
    
    var downloadState: DownloadState {
        viewModel.downloadStates[module.id] ?? .notDownloaded
    }
    
    var downloadProgress: Double {
        viewModel.downloadProgress[module.id] ?? 0.0
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(module.title)
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: iconForModuleType(module.downloadType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(module.downloadType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let fileSize = module.fileSize {
                        Text("• \(formatFileSize(fileSize))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if downloadState == .downloading {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(height: 4)
                    
                    Text("\(Int(downloadProgress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            downloadActionView
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var downloadActionView: some View {
        switch downloadState {
        case .notDownloaded:
            Button {
                Task {
                    await viewModel.downloadModule(module)
                }
            } label: {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.blue)
            }
            .buttonStyle(BorderlessButtonStyle())
            
        case .queued:
            ProgressView()
                .scaleEffect(0.8)
            
        case .downloading:
            HStack(spacing: 8) {
                Button {
                    Task {
                        await viewModel.pauseDownload(itemId: module.id)
                    }
                } label: {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button {
                    Task {
                        await viewModel.cancelDownload(itemId: module.id)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
        case .paused:
            HStack(spacing: 8) {
                Button {
                    Task {
                        await viewModel.resumeDownload(itemId: module.id)
                    }
                } label: {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.green)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button {
                    Task {
                        await viewModel.cancelDownload(itemId: module.id)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
        case .downloaded:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Button {
                    Task {
                        await viewModel.deleteDownload(itemId: module.id)
                    }
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
        case .failed:
            Button {
                Task {
                    await viewModel.resumeDownload(itemId: module.id)
                }
            } label: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
            
        case .cancelling:
            ProgressView()
                .scaleEffect(0.8)
        }
    }
    
    private func iconForModuleType(_ type: ModuleType) -> String {
        switch type {
        case .document: return "doc.fill"
        case .video: return "video.fill"
        case .audio: return "music.note"
        case .youtube: return "play.rectangle.fill"
        case .scorm: return "archivebox.fill"
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - View Model
@MainActor
class DownloadViewModel: ObservableObject {
    private var downloadManager: DownloadManager<Course, SwiftDataDownloadStorage>?
    
    @Published var downloadStates: [UUID: DownloadState] = [:]
    @Published var downloadProgress: [UUID: Double] = [:]
    @Published var activeDownloadsCount: Int = 0
    
    func setupDownloadManager(modelContext: ModelContext) async {
        do {
            let storage = SwiftDataDownloadStorage(modelContainer: modelContext.container)
            
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
                .assign(to: &$downloadStates)
            
            downloadManager?.$downloadProgress
                .assign(to: &$downloadProgress)
            
            downloadManager?.$activeDownloadsCount
                .assign(to: &$activeDownloadsCount)
            
            // Initialize pending downloads
            await downloadManager?.initializePendingTasksFromStorage()
            
        } catch {
            print("Failed to setup download manager: \(error)")
        }
    }
    
    func downloadModule(_ module: Module) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.downloadItem(module) {
                // This closure should create the parent model if needed
                // In this case, we already have the course, so this won't be called
                fatalError("Course should already exist")
            }
        } catch {
            print("Failed to download module: \(error)")
        }
    }
    
    func downloadCourse(_ course: Course) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.downloadModel(course)
        } catch {
            print("Failed to download course: \(error)")
        }
    }
    
    func pauseDownload(itemId: UUID) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.pauseDownload(itemId: itemId)
        } catch {
            print("Failed to pause download: \(error)")
        }
    }
    
    func resumeDownload(itemId: UUID) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.resumeDownload(itemId: itemId)
        } catch {
            print("Failed to resume download: \(error)")
        }
    }
    
    func cancelDownload(itemId: UUID) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.cancelDownload(itemId: itemId)
        } catch {
            print("Failed to cancel download: \(error)")
        }
    }
    
    func deleteDownload(itemId: UUID) async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.deleteDownload(itemId: itemId)
        } catch {
            print("Failed to delete download: \(error)")
        }
    }
    
    func clearAllDownloads() async {
        guard let downloadManager = downloadManager else { return }
        
        do {
            try await downloadManager.clearAllDownloadsAndData()
        } catch {
            print("Failed to clear all downloads: \(error)")
        }
    }
    
    func addDemoCourse(modelContext: ModelContext) {
        // Create demo course with various module types
        let demoCourse = Course(
            courseId: 1,
            title: "iOS Development Mastery",
            courseType: "Programming",
            courseCode: "IOS101",
            description: "Complete iOS development course",
            numberOfModules: 5,
            courseFee: 99.99,
            adminName: "John Doe",
            courseRating: 4.8
        )
        
        // Add demo modules with different types
        let modules = [
            Module(
                moduleId: 1,
                title: "Getting Started with Swift",
                description: "Introduction to Swift programming",
                path: "",
                moduleType: .document,
                duration: 30,
                downloadURL: URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!,
                parentModelId: demoCourse.id
            ),
            Module(
                moduleId: 2,
                title: "SwiftUI Basics",
                description: "Learn SwiftUI fundamentals",
                path: "",
                moduleType: .video,
                duration: 120,
                downloadURL: URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                parentModelId: demoCourse.id
            ),
            Module(
                moduleId: 3,
                title: "WWDC Keynote Highlights",
                description: "Watch the latest WWDC keynote",
                path: "",
                moduleType: .youtube,
                duration: 180,
                youtubeVideoId: "dQw4w9WgXcQ",
                downloadURL: URL(string: "https://youtube.com/watch?v=dQw4w9WgXcQ")!,
                parentModelId: demoCourse.id
            ),
            Module(
                moduleId: 4,
                title: "Swift Audio Guide",
                description: "Audio tutorial for Swift",
                path: "",
                moduleType: .audio,
                duration: 60,
                downloadURL: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!,
                parentModelId: demoCourse.id
            ),
            Module(
                moduleId: 5,
                title: "Interactive Swift Course",
                description: "SCORM package for Swift learning",
                path: "",
                moduleType: .scorm,
                duration: 240,
                downloadURL: URL(string: "https://github.com/ADL-AICC/SCORM-2004-4ed-Test-Suite/archive/master.zip")!,
                parentModelId: demoCourse.id
            )
        ]
        
        demoCourse.modules = modules
        
        // Save to SwiftData
        modelContext.insert(demoCourse)
        
        // Also create a second demo course
        let demoCourse2 = Course(
            courseId: 2,
            title: "Advanced SwiftUI",
            courseType: "Programming",
            courseCode: "IOS201",
            description: "Advanced SwiftUI techniques",
            numberOfModules: 3,
            courseFee: 149.99,
            adminName: "Jane Smith",
            courseRating: 4.9
        )
        
        let modules2 = [
            Module(
                moduleId: 6,
                title: "Custom Views and Modifiers",
                description: "Creating custom SwiftUI components",
                path: "",
                moduleType: .document,
                duration: 45,
                downloadURL: URL(string: "https://www.africau.edu/images/default/sample.pdf")!,
                parentModelId: demoCourse2.id
            ),
            Module(
                moduleId: 7,
                title: "Animations in SwiftUI",
                description: "Master SwiftUI animations",
                path: "",
                moduleType: .video,
                duration: 90,
                downloadURL: URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_2mb.mp4")!,
                parentModelId: demoCourse2.id
            ),
            Module(
                moduleId: 8,
                title: "Performance Optimization",
                description: "Optimize your SwiftUI apps",
                path: "",
                moduleType: .document,
                duration: 60,
                downloadURL: URL(string: "https://unec.edu.az/application/uploads/2014/12/pdf-sample.pdf")!,
                parentModelId: demoCourse2.id
            )
        ]
        
        demoCourse2.modules = modules2
        modelContext.insert(demoCourse2)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save demo courses: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Course.self, Module.self], inMemory: true)
}
