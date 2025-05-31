//
//  ModuleType.swift
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 27/05/25.
//

import Foundation
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
