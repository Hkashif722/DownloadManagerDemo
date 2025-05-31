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
        TabView {
            // All Courses Tab
            AllCoursesView(courses: courses, viewModel: viewModel, modelContext: modelContext)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("All Courses")
                }
            
            // Downloaded Courses Tab
            DownloadedCoursesView(courses: courses, viewModel: viewModel)
                .tabItem {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Downloaded")
                }
        }
        .task {
            await viewModel.setupDownloadManager(modelContext: modelContext)
        }
    }
}

// MARK: - All Courses View
struct AllCoursesView: View {
    let courses: [Course]
    @ObservedObject var viewModel: DownloadViewModel
    let modelContext: ModelContext
    
    var body: some View {
        NavigationStack {
            List {
                if courses.isEmpty {
                    EmptyStateView(viewModel: viewModel, modelContext: modelContext)
                } else {
                    ForEach(courses) { course in
                        CourseRowView(course: course, viewModel: viewModel)
                    }
                    .onDelete(perform: deleteCourses)
                }
            }
            .navigationTitle("All Courses")
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
    }
    
    private func deleteCourses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(courses[index])
            }
        }
    }
}

// MARK: - Downloaded Courses View
struct DownloadedCoursesView: View {
    let courses: [Course]
    @ObservedObject var viewModel: DownloadViewModel
    
    // Filter courses that have at least one downloaded module
    var downloadedCourses: [Course] {
        courses.filter { course in
            course.modules.contains { module in
                let state = viewModel.downloadStates[module.id] ?? .notDownloaded
                return state == .downloaded
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if downloadedCourses.isEmpty {
                    DownloadedEmptyStateView()
                } else {
                    ForEach(downloadedCourses) { course in
                        DownloadedCourseRowView(course: course, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Downloaded Courses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Text("\(downloadedCourses.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}

// MARK: - Downloaded Empty State
struct DownloadedEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle.dotted")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Downloaded Courses")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Download modules from the 'All Courses' tab to see them here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Downloaded Course Row View
struct DownloadedCourseRowView: View {
    let course: Course
    @ObservedObject var viewModel: DownloadViewModel
    @State private var isExpanded = false
    
    // Filter only downloaded modules
    var downloadedModules: [Module] {
        course.modules.filter { module in
            let state = viewModel.downloadStates[module.id] ?? .notDownloaded
            return state == .downloaded
        }
    }
    
    var totalModules: Int {
        course.modules.count
    }
    
    var downloadProgress: Double {
        guard !course.modules.isEmpty else { return 0 }
        let downloadedCount = downloadedModules.count
        return Double(downloadedCount) / Double(totalModules)
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(downloadedModules) { module in
                DownloadedModuleRowView(module: module, viewModel: viewModel)
                    .padding(.vertical, 4)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(course.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Course completion badge
                    if downloadedModules.count == totalModules {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
                
                HStack {
                    Label("\(downloadedModules.count)/\(totalModules) downloaded",
                          systemImage: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Progress indicator
                    Text("\(Int(downloadProgress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                // Progress bar
                ProgressView(value: downloadProgress)
                    .progressViewStyle(.linear)
                    .frame(height: 4)
                    .tint(.blue)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Downloaded Module Row View
struct DownloadedModuleRowView: View {
    let module: Module
    @ObservedObject var viewModel: DownloadViewModel
    
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
                    
                    Spacer()
                    
                    // Downloaded timestamp (if available)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            // Action buttons for downloaded module
            HStack(spacing: 12) {
                // View/Open button
                Button {
                    // In a real app, this would open the downloaded file
                    print("Opening module: \(module.title)")
                } label: {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                // Delete button
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
        }
        .padding(.vertical, 4)
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

struct EmptyStateView: View {
    let viewModel: DownloadViewModel
    let modelContext: ModelContext
    
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
            courseType: "Programming",
            courseCode: "IOS101",
            categoryName: "Mobile Development",
            courseTitle: "iOS Development Mastery",
            numberOfModules: 5,
            completionPeriodDays: 30,
            courseFee: 99.99,
            currency: "USD",
            thumbnailPath: nil,
            description: "Complete iOS development course covering Swift, SwiftUI, and advanced topics",
            learningApproach: true,
            language: "English",
            courseCreditPoints: 10.0,
            adminName: "John Doe",
            courseRating: 4.8,
            courseRatingCount: 125,
            progressPercentage: 0,
            duration: 1200, // 20 hours in minutes
            courseAssignedDate: "2025-05-30",
            lastActivityDate: "2025-05-30"
        )
        
        // Add demo modules with different types
        let modules = [
            Module(
                moduleId: 1,
                moduleName: "Getting Started with Swift",
                path: "/courses/ios101/module1",
                moduleType: .document,
                description: "Introduction to Swift programming language fundamentals",
                duration: 30.0,
                sequenceNo: 1,
                downloadURL: URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!,
                parentModelId: demoCourse.id
            ),
            Module(
                moduleId: 2,
                moduleName: "SwiftUI Basics",
                path: "/courses/ios101/module2",
                moduleType: .video,
                description: "Learn SwiftUI fundamentals and build your first app",
                duration: 120.0,
                sequenceNo: 2,
                downloadURL: URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                parentModelId: demoCourse.id
            ),
            Module(
                moduleId: 3,
                moduleName: "WWDC Keynote Highlights",
                path: "/courses/ios101/module3",
                moduleType: .youtube,
                description: "Watch the latest WWDC keynote and learn about new iOS features",
                duration: 180.0,
                youtubeVideoId: "dQw4w9WgXcQ",
                sequenceNo: 3,
                downloadURL: URL(string: "https://youtube.com/watch?v=dQw4w9WgXcQ")!,
                parentModelId: demoCourse.id
            ),
            Module(
                moduleId: 4,
                moduleName: "Swift Audio Guide",
                path: "/courses/ios101/module4",
                moduleType: .audio,
                description: "Audio tutorial covering Swift best practices and patterns",
                duration: 60.0,
                sequenceNo: 4,
                downloadURL: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!,
                parentModelId: demoCourse.id
            ),
            Module(
                moduleId: 5,
                moduleName: "Interactive Swift Course",
                path: "/courses/ios101/module5",
                moduleType: .scorm,
                description: "SCORM package for interactive Swift learning with hands-on exercises",
                duration: 240.0,
                sequenceNo: 5,
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
            courseType: "Programming",
            courseCode: "IOS201",
            categoryName: "Mobile Development",
            courseTitle: "Advanced SwiftUI",
            numberOfModules: 3,
            completionPeriodDays: 45,
            courseFee: 149.99,
            currency: "USD",
            thumbnailPath: nil,
            description: "Advanced SwiftUI techniques including custom animations, performance optimization, and architectural patterns",
            learningApproach: true,
            language: "English",
            courseCreditPoints: 15.0,
            adminName: "Jane Smith",
            courseRating: 4.9,
            courseRatingCount: 87,
            progressPercentage: 0,
            duration: 1800, // 30 hours in minutes
            courseAssignedDate: "2025-05-30",
            lastActivityDate: "2025-05-30"
        )
        
        let modules2 = [
            Module(
                moduleId: 6,
                moduleName: "Custom Views and Modifiers",
                path: "/courses/ios201/module1",
                moduleType: .document,
                description: "Creating reusable custom SwiftUI components and view modifiers",
                duration: 45.0,
                sequenceNo: 1,
                downloadURL: URL(string: "https://www.africau.edu/images/default/sample.pdf")!,
                parentModelId: demoCourse2.id
            ),
            Module(
                moduleId: 7,
                moduleName: "Animations in SwiftUI",
                path: "/courses/ios201/module2",
                moduleType: .video,
                description: "Master SwiftUI animations, transitions, and gesture handling",
                duration: 90.0,
                sequenceNo: 2,
                downloadURL: URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_2mb.mp4")!,
                parentModelId: demoCourse2.id
            ),
            Module(
                moduleId: 8,
                moduleName: "Performance Optimization",
                path: "/courses/ios201/module3",
                moduleType: .document,
                description: "Optimize your SwiftUI apps for better performance and user experience",
                duration: 60.0,
                sequenceNo: 3,
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
