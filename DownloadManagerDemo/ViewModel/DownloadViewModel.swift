//
//  DownloadViewModel.swift
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 02/06/25.
//

import SwiftUI
import DownloadManager
import Combine
import SwiftData

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
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save demo course: \(error)")
        }
    }
    
    func addMultipleDemoCourses(modelContext: ModelContext) {
        // Add the original demo course
        addDemoCourse(modelContext: modelContext)
        
        // Add a second demo course
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
