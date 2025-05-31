//
//  Module.swift - Fixed Version
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 27/05/25.
//

import Foundation
import SwiftData
import DownloadManager

// MARK: - Module Model
@Model
final class Module: DownloadableItem {
    typealias DownloadType = ModuleType
    
    @Attribute(.unique) var id: UUID
    var moduleId: Int
    var moduleName: String
    var mimeType: String?
    var isSecuredContent: Bool
    var path: String
    var zipPath: String?
    var moduleTypeRaw: String
    var actualModuleType: String?
    var thumbnail: String
    var moduleDescription: String
    var assesmentType: String?
    var isLearnerFeedback: Bool
    var isTrainerFeedback: Bool
    var isMobileCompatible: Bool
    var duration: Double
    var creditPoints: Int
    var preAssessmentId: Int
    var assessmentId: Int
    var feedbackId: Int
    var lcmsId: Int
    var youtubeVideoId: String?
    var externalLCMSId: Int?
    var isPreAssessment: Bool
    var isAssessment: Bool
    var isFeedback: Bool
    var status: String
    var assessmentStatus: String?
    var preAssessmentStatus: String?
    var feedbackStatus: String?
    var contentStatus: String
    var sectionId: Int?
    var batchId: Int
    var batchCode: String
    var batchName: String
    var scheduleID: Int
    var scheduleCode: String
    var startDate: String?
    var endDate: String?
    var registrationEndDate: String?
    var startTime: String?
    var endTime: String?
    var placeName: String
    var city: String
    var address: String
    var trainingRequestStatus: String
    var sequenceNo: Int
    var location: String
    var finalDate: String
    var completionPeriodDays: Int
    var isEnableModule: Bool
    var activityID: Int?
    var isMultilingual: Bool
    var selectedLanguageCode: String
    var isEmbed: Bool
    var attendanceStatus: String
    var waiverStatus: String
    var scheduleCreatedBy: Int
    var tz_StartDt: String
    var tz_EndDt: String
    var academyAgencyName: String
    var feedbackRating: Double?
    var trainerName: String?
    var scheduleFeedbackId: Int?
    var scheduleFeedbackStatus: String?
    var assignmentId: Int
    var isAssignment: Bool
    var assignmentStatus: String
    
    // DownloadableItem protocol requirements
    var downloadURLString: String // Store URL as string for SwiftData
    var localFileURLString: String? // Store URL as string for SwiftData
    var downloadStateRaw: String
    var downloadProgress: Double
    var fileSize: Int64?
    
    // SwiftData relationship - FIXED: Simplified relationship
    var parentCourse: Course?
    
    // Protocol conformances - computed properties
    @Transient var downloadURL: URL {
        get { URL(string: downloadURLString) ?? URL(string: "https://example.com")! }
        set { downloadURLString = newValue.absoluteString }
    }
    
    @Transient var localFileURL: URL? {
        get {
            guard let urlString = localFileURLString else { return nil }
            return URL(string: urlString)
        }
        set { localFileURLString = newValue?.absoluteString }
    }
    
    @Transient var downloadType: ModuleType {
        ModuleType(rawValue: moduleTypeRaw) ?? .document
    }
    
    @Transient var downloadState: DownloadState {
        get { DownloadState(rawValue: downloadStateRaw) ?? .notDownloaded }
        set { downloadStateRaw = newValue.rawValue }
    }
    
    @Transient var parentModelId: UUID? {
        get { parentCourse?.id }
        set {
            // This setter is for protocol conformance but actual relationship
            // management should be done through the parentCourse property
        }
    }
    
    // Computed property for backward compatibility
    @Transient var title: String {
        get { moduleName }
        set { moduleName = newValue }
    }
    
    init(
        id: UUID = UUID(),
        moduleId: Int,
        moduleName: String,
        mimeType: String? = nil,
        isSecuredContent: Bool = false,
        path: String,
        zipPath: String? = nil,
        moduleType: ModuleType,
        actualModuleType: String? = nil,
        thumbnail: String = "",
        description: String,
        assesmentType: String? = nil,
        isLearnerFeedback: Bool = false,
        isTrainerFeedback: Bool = false,
        isMobileCompatible: Bool = false,
        duration: Double,
        creditPoints: Int = 0,
        preAssessmentId: Int = 0,
        assessmentId: Int = 0,
        feedbackId: Int = 0,
        lcmsId: Int = 0,
        youtubeVideoId: String? = nil,
        externalLCMSId: Int? = nil,
        isPreAssessment: Bool = false,
        isAssessment: Bool = false,
        isFeedback: Bool = false,
        status: String = "incompleted",
        assessmentStatus: String? = nil,
        preAssessmentStatus: String? = nil,
        feedbackStatus: String? = nil,
        contentStatus: String = "incompleted",
        sectionId: Int? = nil,
        batchId: Int = 0,
        batchCode: String = "",
        batchName: String = "",
        scheduleID: Int = 0,
        scheduleCode: String = "",
        startDate: String? = nil,
        endDate: String? = nil,
        registrationEndDate: String? = nil,
        startTime: String? = nil,
        endTime: String? = nil,
        placeName: String = "",
        city: String = "",
        address: String = "",
        trainingRequestStatus: String = "",
        sequenceNo: Int,
        location: String = "",
        finalDate: String = "",
        completionPeriodDays: Int = 0,
        isEnableModule: Bool = true,
        activityID: Int? = nil,
        isMultilingual: Bool = false,
        selectedLanguageCode: String = "en",
        isEmbed: Bool = false,
        attendanceStatus: String = "",
        waiverStatus: String = "ATTENDANCE",
        scheduleCreatedBy: Int = 0,
        tz_StartDt: String = "0001-01-01T00:00:00",
        tz_EndDt: String = "0001-01-01T00:00:00",
        academyAgencyName: String = "",
        feedbackRating: Double? = nil,
        trainerName: String? = nil,
        scheduleFeedbackId: Int? = nil,
        scheduleFeedbackStatus: String? = nil,
        assignmentId: Int = 0,
        isAssignment: Bool = false,
        assignmentStatus: String = "",
        downloadURL: URL,
        parentModelId: UUID? = nil // For backward compatibility, but managed by SwiftData relationship
    ) {
        self.id = id
        self.moduleId = moduleId
        self.moduleName = moduleName
        self.mimeType = mimeType
        self.isSecuredContent = isSecuredContent
        self.path = path
        self.zipPath = zipPath
        self.moduleTypeRaw = moduleType.rawValue
        self.actualModuleType = actualModuleType
        self.thumbnail = thumbnail
        self.moduleDescription = description
        self.assesmentType = assesmentType
        self.isLearnerFeedback = isLearnerFeedback
        self.isTrainerFeedback = isTrainerFeedback
        self.isMobileCompatible = isMobileCompatible
        self.duration = duration
        self.creditPoints = creditPoints
        self.preAssessmentId = preAssessmentId
        self.assessmentId = assessmentId
        self.feedbackId = feedbackId
        self.lcmsId = lcmsId
        self.youtubeVideoId = youtubeVideoId
        self.externalLCMSId = externalLCMSId
        self.isPreAssessment = isPreAssessment
        self.isAssessment = isAssessment
        self.isFeedback = isFeedback
        self.status = status
        self.assessmentStatus = assessmentStatus
        self.preAssessmentStatus = preAssessmentStatus
        self.feedbackStatus = feedbackStatus
        self.contentStatus = contentStatus
        self.sectionId = sectionId
        self.batchId = batchId
        self.batchCode = batchCode
        self.batchName = batchName
        self.scheduleID = scheduleID
        self.scheduleCode = scheduleCode
        self.startDate = startDate
        self.endDate = endDate
        self.registrationEndDate = registrationEndDate
        self.startTime = startTime
        self.endTime = endTime
        self.placeName = placeName
        self.city = city
        self.address = address
        self.trainingRequestStatus = trainingRequestStatus
        self.sequenceNo = sequenceNo
        self.location = location
        self.finalDate = finalDate
        self.completionPeriodDays = completionPeriodDays
        self.isEnableModule = isEnableModule
        self.activityID = activityID
        self.isMultilingual = isMultilingual
        self.selectedLanguageCode = selectedLanguageCode
        self.isEmbed = isEmbed
        self.attendanceStatus = attendanceStatus
        self.waiverStatus = waiverStatus
        self.scheduleCreatedBy = scheduleCreatedBy
        self.tz_StartDt = tz_StartDt
        self.tz_EndDt = tz_EndDt
        self.academyAgencyName = academyAgencyName
        self.feedbackRating = feedbackRating
        self.trainerName = trainerName
        self.scheduleFeedbackId = scheduleFeedbackId
        self.scheduleFeedbackStatus = scheduleFeedbackStatus
        self.assignmentId = assignmentId
        self.isAssignment = isAssignment
        self.assignmentStatus = assignmentStatus
        
        // Download-related properties
        self.downloadURLString = downloadURL.absoluteString
        self.localFileURLString = nil
        self.downloadStateRaw = DownloadState.notDownloaded.rawValue
        self.downloadProgress = 0.0
        self.fileSize = nil
    }
}
