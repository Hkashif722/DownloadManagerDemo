//
//  DownloadViewModel.swift (Complete)
//  DownloadManagerDemo
//
//  Complete version with working demo course creation
//

import SwiftUI
import DownloadManager
import Combine
import SwiftData

// MARK: - View Model (Complete)
@MainActor
class DownloadViewModel: ObservableObject {
    private let centralManager = CentralizedDownloadManager.shared
    
    var downloadStates: [UUID: DownloadState] {
        centralManager.downloadStates
    }
    
    var downloadProgress: [UUID: Double] {
        centralManager.downloadProgress
    }
    
    var activeDownloadsCount: Int {
        centralManager.activeDownloadsCount
    }
    
    func setupDownloadManager(modelContext: ModelContext) async {
        await centralManager.initialize(modelContext: modelContext)
    }
    
    func downloadModule(_ module: Module) async {
        await centralManager.downloadModule(module)
    }
    
    func downloadCourse(_ course: Course) async {
        await centralManager.downloadCourse(course)
    }
    
    func pauseDownload(itemId: UUID) async {
        await centralManager.pauseDownload(itemId: itemId)
    }
    
    func resumeDownload(itemId: UUID) async {
        await centralManager.resumeDownload(itemId: itemId)
    }
    
    func cancelDownload(itemId: UUID) async {
        await centralManager.cancelDownload(itemId: itemId)
    }
    
    func deleteDownload(itemId: UUID) async {
        await centralManager.deleteDownload(itemId: itemId)
    }
    
    func clearAllDownloads() async {
        await centralManager.clearAllDownloads()
    }
    
    // MARK: - Demo Course Creation
    func addDemoCourse(modelContext: ModelContext) {
        print("🎯 Creating demo course...")
        
        do {
            // Create demo course
            let demoCourse = Course(
                courseId: 1001,
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
                duration: 120, // 20 hours in minutes
                courseAssignedDate: "2025-05-30",
                lastActivityDate: "2025-05-30"
            )
            
            // Insert course first
            modelContext.insert(demoCourse)
            
            // Create demo modules with different types
            let modules = createDemoModules(for: demoCourse)
            
            // Insert each module and establish relationship
            for module in modules {
                modelContext.insert(module)
                demoCourse.addModule(module) // Use the relationship method
            }
            
            // Save the context
            try modelContext.save()
            
            print("✅ Demo course created successfully with \(modules.count) modules")
            print("📚 Course: \(demoCourse.courseTitle)")
            print("📝 Modules: \(modules.map { $0.moduleName }.joined(separator: ", "))")
            
        } catch {
            print("❌ Failed to create demo course: \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }
    
    func addMultipleDemoCourses(modelContext: ModelContext) {
        print("🎯 Creating multiple demo courses...")
        
        do {
            // First demo course (iOS Development)
            let demoCourse1 = Course(
                courseId: 1001,
                courseType: "Programming",
                courseCode: "IOS101",
                categoryName: "Mobile Development",
                courseTitle: "iOS Development Mastery",
                numberOfModules: 5,
                completionPeriodDays: 30,
                courseFee: 99.99,
                currency: "USD",
                description: "Complete iOS development course covering Swift, SwiftUI, and advanced topics",
                adminName: "John Doe",
                courseRating: 4.8,
                courseRatingCount: 125,
                duration: 1200
            )
            
            // Second demo course (Advanced SwiftUI)
            let demoCourse2 = Course(
                courseId: 1002,
                courseType: "Programming",
                courseCode: "IOS201",
                categoryName: "Mobile Development",
                courseTitle: "Advanced SwiftUI Techniques",
                numberOfModules: 4,
                completionPeriodDays: 45,
                courseFee: 149.99,
                currency: "USD",
                description: "Advanced SwiftUI techniques including custom animations, performance optimization, and architectural patterns",
                adminName: "Jane Smith",
                courseRating: 4.9,
                courseRatingCount: 87,
                duration: 1800
            )
            
            // Third demo course (Web Development)
            let demoCourse3 = Course(
                courseId: 1003,
                courseType: "Web Development",
                courseCode: "WEB101",
                categoryName: "Frontend Development",
                courseTitle: "Modern Web Development",
                numberOfModules: 3,
                completionPeriodDays: 60,
                courseFee: 79.99,
                currency: "USD",
                description: "Learn modern web development with HTML5, CSS3, and JavaScript",
                adminName: "Alex Johnson",
                courseRating: 4.7,
                courseRatingCount: 156,
                duration: 900
            )
            
            let courses = [demoCourse1, demoCourse2, demoCourse3]
            
            // Insert courses first
            for course in courses {
                modelContext.insert(course)
            }
            
            // Create and insert modules for each course
            let modules1 = createDemoModules(for: demoCourse1)
            let modules2 = createAdvancedSwiftUIModules(for: demoCourse2)
            let modules3 = createWebDevelopmentModules(for: demoCourse3)
            
            let allModules = [modules1, modules2, modules3]
            
            for (index, modules) in allModules.enumerated() {
                let course = courses[index]
                for module in modules {
                    modelContext.insert(module)
                    course.addModule(module)
                }
            }
            
            // Save the context
            try modelContext.save()
            
            let totalModules = allModules.flatMap { $0 }.count
            print("✅ Multiple demo courses created successfully!")
            print("📚 Created \(courses.count) courses with \(totalModules) total modules")
            
            for course in courses {
                print("  - \(course.courseTitle) (\(course.modules.count) modules)")
            }
            
        } catch {
            print("❌ Failed to create multiple demo courses: \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Module Creation Helpers
    private func createDemoModules(for course: Course) -> [Module] {
        return [
            Module(
                moduleId: 2001,
                moduleName: "Getting Started with Swift",
                path: "/courses/ios101/module1",
                moduleType: .document,
                description: "Introduction to Swift programming language fundamentals",
                duration: 30.0,
                sequenceNo: 1,
                downloadURL: URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!,
                parentModelId: course.id
            ),
            Module(
                moduleId: 2002,
                moduleName: "SwiftUI Basics Video Tutorial",
                path: "/courses/ios101/module2",
                moduleType: .video,
                description: "Learn SwiftUI fundamentals and build your first app",
                duration: 120.0,
                sequenceNo: 2,
                downloadURL: URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                parentModelId: course.id
            ),
            Module(
                moduleId: 2003,
                moduleName: "WWDC Keynote Highlights",
                path: "/courses/ios101/module3",
                moduleType: .youtube,
                description: "Watch the latest WWDC keynote and learn about new iOS features",
                duration: 180.0,
                youtubeVideoId: "dQw4w9WgXcQ",
                sequenceNo: 3,
                downloadURL: URL(string: "https://youtube.com/watch?v=dQw4w9WgXcQ")!,
                parentModelId: course.id
            ),
            Module(
                moduleId: 2004,
                moduleName: "Swift Audio Guide",
                path: "/courses/ios101/module4",
                moduleType: .audio,
                description: "Audio tutorial covering Swift best practices and patterns",
                duration: 60.0,
                sequenceNo: 4,
                downloadURL: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!,
                parentModelId: course.id
            ),
            Module(
                moduleId: 2005,
                moduleName: "Interactive Swift Course Package",
                path: "/courses/ios101/module5",
                moduleType: .scorm,
                description: "SCORM package for interactive Swift learning with hands-on exercises",
                duration: 240.0,
                sequenceNo: 5,
                downloadURL: URL(string: "https://github.com/ADL-AICC/SCORM-2004-4ed-Test-Suite/archive/master.zip")!,
                parentModelId: course.id
            )
        ]
    }
    
    private func createAdvancedSwiftUIModules(for course: Course) -> [Module] {
        return [
            Module(
                moduleId: 3001,
                moduleName: "Custom Views and Modifiers",
                path: "/courses/ios201/module1",
                moduleType: .document,
                description: "Creating reusable custom SwiftUI components and view modifiers",
                duration: 45.0,
                sequenceNo: 1,
                downloadURL: URL(string: "https://www.africau.edu/images/default/sample.pdf")!,
                parentModelId: course.id
            ),
            Module(
                moduleId: 3002,
                moduleName: "Advanced Animations Tutorial",
                path: "/courses/ios201/module2",
                moduleType: .video,
                description: "Master SwiftUI animations, transitions, and gesture handling",
                duration: 90.0,
                sequenceNo: 2,
                downloadURL: URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_2mb.mp4")!,
                parentModelId: course.id
            ),
            Module(
                moduleId: 3003,
                moduleName: "Performance Optimization Guide",
                path: "/courses/ios201/module3",
                moduleType: .document,
                description: "Optimize your SwiftUI apps for better performance and user experience",
                duration: 60.0,
                sequenceNo: 3,
                downloadURL: URL(string: "https://unec.edu.az/application/uploads/2014/12/pdf-sample.pdf")!,
                parentModelId: course.id
            ),
            Module(
                moduleId: 3004,
                moduleName: "SwiftUI Architecture Patterns",
                path: "/courses/ios201/module4",
                moduleType: .audio,
                description: "Learn about MVVM, Redux, and other architectural patterns in SwiftUI",
                duration: 75.0,
                sequenceNo: 4,
                downloadURL: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3")!,
                parentModelId: course.id
            )
        ]
    }
    
    private func createWebDevelopmentModules(for course: Course) -> [Module] {
        return [
            Module(
                moduleId: 4001,
                moduleName: "HTML5 and CSS3 Fundamentals",
                path: "/courses/web101/module1",
                moduleType: .document,
                description: "Master the fundamentals of HTML5 and modern CSS3 techniques",
                duration: 50.0,
                sequenceNo: 1,
                downloadURL: URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!,
                parentModelId: course.id
            ),
            Module(
                moduleId: 4002,
                moduleName: "JavaScript ES6+ Features",
                path: "/courses/web101/module2",
                moduleType: .video,
                description: "Learn modern JavaScript features including arrow functions, async/await, and more",
                duration: 100.0,
                sequenceNo: 2,
                downloadURL: URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                parentModelId: course.id
            ),
            Module(
                moduleId: 4003,
                moduleName: "Responsive Web Design",
                path: "/courses/web101/module3",
                moduleType: .scorm,
                description: "Interactive course on creating responsive layouts for all devices",
                duration: 80.0,
                sequenceNo: 3,
                downloadURL: URL(string: "https://github.com/ADL-AICC/SCORM-2004-4ed-Test-Suite/archive/master.zip")!,
                parentModelId: course.id
            )
        ]
    }
}

// MARK: - Additional Helper Methods
extension DownloadViewModel {
    
    /// Get download state for a specific item
    func getDownloadState(for itemId: UUID) -> DownloadState? {
        return downloadStates[itemId]
    }
    
    /// Get download progress for a specific item
    func getDownloadProgress(for itemId: UUID) -> Double {
        return downloadProgress[itemId] ?? 0.0
    }
    
    /// Check if an item is currently downloading
    func isDownloading(itemId: UUID) -> Bool {
        return downloadStates[itemId] == .downloading
    }
    
    /// Check if an item is downloaded
    func isDownloaded(itemId: UUID) -> Bool {
        return downloadStates[itemId] == .downloaded
    }
    
    /// Check if an item is paused
    func isPaused(itemId: UUID) -> Bool {
        return downloadStates[itemId] == .paused
    }
    
    /// Get formatted progress percentage
    func getFormattedProgress(for itemId: UUID) -> String {
        let progress = getDownloadProgress(for: itemId)
        return String(format: "%.1f%%", progress * 100)
    }
    
    /// Get all active downloads
    func getActiveDownloads() -> [UUID] {
        return downloadStates.compactMap { key, value in
            value == .downloading ? key : nil
        }
    }
    
    /// Get all completed downloads
    func getCompletedDownloads() -> [UUID] {
        return downloadStates.compactMap { key, value in
            value == .downloaded ? key : nil
        }
    }
    
    /// Clear completed downloads from tracking
    func clearCompletedDownloads() async {
        let completedIds = getCompletedDownloads()
        for id in completedIds {
            await deleteDownload(itemId: id)
        }
    }
    
    /// Retry failed downloads
    func retryFailedDownloads() async {
        let failedIds = downloadStates.compactMap { key, value in
            value == .failed ? key : nil
        }
        
        for id in failedIds {
            await resumeDownload(itemId: id)
        }
    }
}

// MARK: - Demo Data Cleanup
extension DownloadViewModel {
    
    /// Remove all demo courses and modules
    func removeAllDemoData(modelContext: ModelContext) {
        print("🧹 Cleaning up demo data...")
        
        do {
            // Fetch all courses with demo IDs
            let demoCourseIds = [1001, 1002, 1003]
            let courseDescriptor = FetchDescriptor<Course>(
                predicate: #Predicate<Course> { course in
                    demoCourseIds.contains(course.courseId)
                }
            )
            
            let demoCoursesToDelete = try modelContext.fetch(courseDescriptor)
            
            // Delete courses (modules should cascade delete)
            for course in demoCoursesToDelete {
                modelContext.delete(course)
            }
            
            try modelContext.save()
            
            print("✅ Removed \(demoCoursesToDelete.count) demo courses")
            
        } catch {
            print("❌ Failed to remove demo data: \(error)")
        }
    }
}
