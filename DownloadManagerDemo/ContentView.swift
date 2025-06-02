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
            
            // Online Modules Tab (NEW)
            OnlineModuleDemoView()
                .tabItem {
                    Image(systemName: "globe.badge.chevron.down")
                    Text("Online Modules")
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
                    Menu {
                        Button("Add Demo Course") {
                            viewModel.addDemoCourse(modelContext: modelContext)
                        }
                        
                        Button("Add Multiple Demo Courses") {
                            viewModel.addMultipleDemoCourses(modelContext: modelContext)
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
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
    @State private var showingPlayer = false
    
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
                    showingPlayer = true
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
        .sheet(isPresented: $showingPlayer) {
            if let localURL = module.localFileURL {
                ModulePlayerSheet(url: localURL, title: module.title, moduleType: module.downloadType)
            }
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
            Text("Tap '+' to create sample courses")
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



#Preview {
    ContentView()
        .modelContainer(for: [Course.self, Module.self], inMemory: true)
}
