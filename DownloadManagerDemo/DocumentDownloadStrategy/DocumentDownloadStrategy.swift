//
//  DocumentDownloadStrategy.swift
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 27/05/25.
//


// MARK: - Demo App Models
import Foundation
import SwiftData
import DownloadManager


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