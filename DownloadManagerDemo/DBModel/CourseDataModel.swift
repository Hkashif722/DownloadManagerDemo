//
//  Course.swift - Fixed Version
//  DownloadManagerDemo
//

import Foundation
import SwiftData
import DownloadManager

// MARK: - Course Model
@Model
final class Course: DownloadableModel {
    typealias ItemType = Module
    
    @Attribute(.unique) var id: UUID
    var courseId: Int
    var courseType: String
    var courseCode: String
    var categoryName: String
    var courseTitle: String
    var numberOfModules: Int
    var completionPeriodDays: Int
    var courseFee: Double
    var currency: String
    var thumbnailPath: String?
    var courseDescription: String
    var learningApproach: Bool
    var language: String
    var courseCreditPoints: Double
    var preAssessmentId: Int
    var assessmentId: Int
    var feedbackId: Int
    var isFeedbackOptional: Bool
    var assignmentId: Int
    var isPreAssessment: Bool
    var isAssessment: Bool
    var isFeedback: Bool
    var isAssignment: Bool
    var isCertificateIssued: Bool
    var status: String
    var assessmentStatus: String
    var preAssessmentStatus: String
    var feedbackStatus: String?
    var contentStatus: String
    var adminName: String
    var courseRating: Double
    var courseRatingCount: Int
    var isAdaptiveLearning: Bool
    var progressPercentage: Int
    var duration: Int
    var courseAssignedDate: String
    var lastActivityDate: String
    var isDilinkingILT: Bool
    var assignmentStatus: String
    var isModuleHasAssFeed: Bool
    var isManagerEvaluation: Bool
    var managerEvaluationStatus: String
    var isPreRequisiteCourse: Bool
    var isShowViewBatches: Bool
    var expiryMessage: String?
    var isCourseExpired: Bool?
    var externalProvider: String?
    var externalProviderCategory: String?
    var isOJT: Bool
    var ojtStatus: String
    var ojtId: Int
    var isVisibleAssessmentDetails: Bool
    var startDate: String
    var endDate: String
    var retrainingDate: String
    var assignmentType: String
    var feedbackRating: Double?
    var aasectId: Int
    var isANCC: Bool
    var faqPath: String
    var metadataJSON: String?
    
    // SwiftData relationship - FIXED: Removed inverse parameter
    @Relationship(deleteRule: .cascade)
    var modules: [Module] = []
    
    // Protocol requirement - use @Transient for computed property
    @Transient var items: [Module] {
        get { modules }
        set { modules = newValue }
    }
    
    // Protocol requirement - use @Transient for computed property
    @Transient var metadata: [String: String]? {
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
    
    // Protocol requirement - use @Transient for computed property
    @Transient var title: String {
        get { courseTitle }
        set { courseTitle = newValue }
    }
    
    // MARK: - Relationship Management
    func addModule(_ module: Module) {
        modules.append(module)
        module.parentCourse = self
    }
    
    func removeModule(_ module: Module) {
        modules.removeAll { $0.id == module.id }
        module.parentCourse = nil
    }
    
    init(
        id: UUID = UUID(),
        courseId: Int,
        courseType: String,
        courseCode: String,
        categoryName: String = "",
        courseTitle: String,
        numberOfModules: Int,
        completionPeriodDays: Int = -1,
        courseFee: Double,
        currency: String = "",
        thumbnailPath: String? = nil,
        description: String,
        learningApproach: Bool = false,
        language: String = "",
        courseCreditPoints: Double = 0.0,
        preAssessmentId: Int = 0,
        assessmentId: Int = 0,
        feedbackId: Int = 0,
        isFeedbackOptional: Bool = false,
        assignmentId: Int = 0,
        isPreAssessment: Bool = false,
        isAssessment: Bool = false,
        isFeedback: Bool = false,
        isAssignment: Bool = false,
        isCertificateIssued: Bool = false,
        status: String = "inprogress",
        assessmentStatus: String = "incompleted",
        preAssessmentStatus: String = "completed",
        feedbackStatus: String? = nil,
        contentStatus: String = "inprogress",
        adminName: String,
        courseRating: Double,
        courseRatingCount: Int = 0,
        isAdaptiveLearning: Bool = false,
        progressPercentage: Int = 0,
        duration: Int = 0,
        courseAssignedDate: String = "",
        lastActivityDate: String = "",
        isDilinkingILT: Bool = false,
        assignmentStatus: String = "",
        isModuleHasAssFeed: Bool = false,
        isManagerEvaluation: Bool = false,
        managerEvaluationStatus: String = "NA",
        isPreRequisiteCourse: Bool = false,
        isShowViewBatches: Bool = false,
        expiryMessage: String? = nil,
        isCourseExpired: Bool? = nil,
        externalProvider: String? = nil,
        externalProviderCategory: String? = nil,
        isOJT: Bool = false,
        ojtStatus: String = "NA",
        ojtId: Int = 0,
        isVisibleAssessmentDetails: Bool = true,
        startDate: String = "",
        endDate: String = "",
        retrainingDate: String = "NA",
        assignmentType: String = "",
        feedbackRating: Double? = nil,
        aasectId: Int = 0,
        isANCC: Bool = false,
        faqPath: String = ""
    ) {
        self.id = id
        self.courseId = courseId
        self.courseType = courseType
        self.courseCode = courseCode
        self.categoryName = categoryName
        self.courseTitle = courseTitle
        self.numberOfModules = numberOfModules
        self.completionPeriodDays = completionPeriodDays
        self.courseFee = courseFee
        self.currency = currency
        self.thumbnailPath = thumbnailPath
        self.courseDescription = description
        self.learningApproach = learningApproach
        self.language = language
        self.courseCreditPoints = courseCreditPoints
        self.preAssessmentId = preAssessmentId
        self.assessmentId = assessmentId
        self.feedbackId = feedbackId
        self.isFeedbackOptional = isFeedbackOptional
        self.assignmentId = assignmentId
        self.isPreAssessment = isPreAssessment
        self.isAssessment = isAssessment
        self.isFeedback = isFeedback
        self.isAssignment = isAssignment
        self.isCertificateIssued = isCertificateIssued
        self.status = status
        self.assessmentStatus = assessmentStatus
        self.preAssessmentStatus = preAssessmentStatus
        self.feedbackStatus = feedbackStatus
        self.contentStatus = contentStatus
        self.adminName = adminName
        self.courseRating = courseRating
        self.courseRatingCount = courseRatingCount
        self.isAdaptiveLearning = isAdaptiveLearning
        self.progressPercentage = progressPercentage
        self.duration = duration
        self.courseAssignedDate = courseAssignedDate
        self.lastActivityDate = lastActivityDate
        self.isDilinkingILT = isDilinkingILT
        self.assignmentStatus = assignmentStatus
        self.isModuleHasAssFeed = isModuleHasAssFeed
        self.isManagerEvaluation = isManagerEvaluation
        self.managerEvaluationStatus = managerEvaluationStatus
        self.isPreRequisiteCourse = isPreRequisiteCourse
        self.isShowViewBatches = isShowViewBatches
        self.expiryMessage = expiryMessage
        self.isCourseExpired = isCourseExpired
        self.externalProvider = externalProvider
        self.externalProviderCategory = externalProviderCategory
        self.isOJT = isOJT
        self.ojtStatus = ojtStatus
        self.ojtId = ojtId
        self.isVisibleAssessmentDetails = isVisibleAssessmentDetails
        self.startDate = startDate
        self.endDate = endDate
        self.retrainingDate = retrainingDate
        self.assignmentType = assignmentType
        self.feedbackRating = feedbackRating
        self.aasectId = aasectId
        self.isANCC = isANCC
        self.faqPath = faqPath
    }
}
