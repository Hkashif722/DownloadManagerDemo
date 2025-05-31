//
//  CourseResponse.swift
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 27/05/25.
//

import Foundation

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
    
    // Optional fields that might come from API
    let categoryName: String?
    let completionPeriodDays: Int?
    let currency: String?
    let language: String?
    let courseCreditPoints: Double?
    let courseRatingCount: Int?
    let duration: Int?
    let courseAssignedDate: String?
    let lastActivityDate: String?
    let progressPercentage: Int?
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
    
    // Optional fields that might come from API
    let sequenceNo: Int?
    let thumbnail: String?
    let creditPoints: Int?
    let status: String?
    let contentStatus: String?
    let isEnableModule: Bool?
}

// MARK: - Course Parser
class CourseParser {
    static func parseCourse(from response: CourseResponse, baseURL: String) -> Course {
        let course = Course(
            courseId: response.courseId,
            courseType: response.courseType,
            courseCode: response.courseCode,
            categoryName: response.categoryName ?? "",
            courseTitle: response.courseTitle,
            numberOfModules: response.numberofModules,
            completionPeriodDays: response.completionPeriodDays ?? -1,
            courseFee: response.courseFee,
            currency: response.currency ?? "USD",
            thumbnailPath: response.thumbnailPath,
            description: response.description,
            learningApproach: false,
            language: response.language ?? "English",
            courseCreditPoints: response.courseCreditPoints ?? 0.0,
            adminName: response.adminName,
            courseRating: response.courseRating,
            courseRatingCount: response.courseRatingCount ?? 0,
            progressPercentage: response.progressPercentage ?? 0,
            duration: response.duration ?? 0,
            courseAssignedDate: response.courseAssignedDate ?? "",
            lastActivityDate: response.lastActivityDate ?? ""
        )
        
        // Parse modules
        course.modules = response.modules.enumerated().map { (index, moduleResponse) in
            // Construct download URL - in real app, this would be properly decrypted/constructed
            let downloadURL = URL(string: "\(baseURL)/download/\(moduleResponse.path)") ?? URL(string: "https://example.com")!
            
            return Module(
                moduleId: moduleResponse.moduleId,
                moduleName: moduleResponse.moduleName,
                mimeType: moduleResponse.mimeType,
                isSecuredContent: moduleResponse.isSecuredContent,
                path: moduleResponse.path,
                zipPath: moduleResponse.zipPath,
                moduleType: ModuleType(rawValue: moduleResponse.moduleType) ?? .document,
                thumbnail: moduleResponse.thumbnail ?? "",
                description: moduleResponse.description,
                duration: moduleResponse.duration,
                creditPoints: moduleResponse.creditPoints ?? 0,
                youtubeVideoId: moduleResponse.youtubeVideoId,
                status: moduleResponse.status ?? "incompleted",
                contentStatus: moduleResponse.contentStatus ?? "incompleted",
                sequenceNo: moduleResponse.sequenceNo ?? (index + 1), // Use index + 1 if not provided
                isEnableModule: moduleResponse.isEnableModule ?? true,
                downloadURL: downloadURL,
                parentModelId: course.id
            )
        }
        
        return course
    }
    
    // Helper method to parse multiple courses
    static func parseCourses(from responses: [CourseResponse], baseURL: String) -> [Course] {
        return responses.map { parseCourse(from: $0, baseURL: baseURL) }
    }
    
    // Helper method to create Course from minimal data (for testing/demo purposes)
    static func createMinimalCourse(
        courseId: Int,
        title: String,
        courseType: String = "General",
        courseCode: String = "GEN001",
        description: String = "Course description",
        adminName: String = "Admin",
        rating: Double = 4.0
    ) -> Course {
        return Course(
            courseId: courseId,
            courseType: courseType,
            courseCode: courseCode,
            categoryName: "General",
            courseTitle: title,
            numberOfModules: 0,
            courseFee: 0.0,
            description: description,
            adminName: adminName,
            courseRating: rating
        )
    }
}
