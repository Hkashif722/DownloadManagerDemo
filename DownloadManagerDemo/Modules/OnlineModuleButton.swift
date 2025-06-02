//
//  OnlineModuleButton.swift
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 02/06/25.
//

import SwiftUI
import DownloadManager
import AVKit
import Combine

// MARK: - Online Module Button
struct OnlineModuleButton: View {
    @Environment(\.modelContext) private var modelContext
    let url: String
    let courseId: UUID?
    let title: String?
    let moduleType: ModuleType
    
    @StateObject private var manager = OnlineModuleManager()
    @State private var showingPlayer = false
    
    // Computed properties for clean UI
    private var isDownloaded: Bool {
        manager.downloadState == .downloaded
    }
    
    private var isDownloading: Bool {
        [.downloading, .queued].contains(manager.downloadState)
    }
    
    private var downloadProgress: Double {
        manager.downloadProgress
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Module info
            VStack(alignment: .leading, spacing: 4) {
                Text(title ?? "Module")
                    .font(.headline)
                    .lineLimit(1)
                
                Text(url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if isDownloading {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(height: 4)
                }
            }
            
            Spacer()
            
            // Action buttons based on state
            actionButtons
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            manager.setup(modelContext: modelContext,url: url, courseId: courseId, title: title, moduleType: moduleType)
        }
        .sheet(isPresented: $showingPlayer) {
            if let playURL = manager.getPlayableURL() {
                ModulePlayerSheet(url: playURL, title: title ?? "Module", moduleType: moduleType)
            }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        switch manager.downloadState {
        case .notDownloaded, .failed:
            // Download button
            Button {
                Task {
                    await manager.download()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Download")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.blue)
                .cornerRadius(8)
            }
            
        case .downloading:
            // Pause button during download
            Button {
                Task {
                    await manager.pause()
                }
            } label: {
                HStack {
                    Image(systemName: "pause.circle.fill")
                    Text("Pause")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.orange)
                .cornerRadius(8)
            }
            
        case .paused:
            // Resume button
            Button {
                Task {
                    await manager.resume()
                }
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Resume")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.green)
                .cornerRadius(8)
            }
            
        case .downloaded:
            // Play and Delete buttons
            HStack(spacing: 8) {
                Button {
                    showingPlayer = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.green)
                    .cornerRadius(8)
                }
                
                Button {
                    Task {
                        await manager.delete()
                    }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.red)
                        .cornerRadius(8)
                }
            }
            
        case .queued, .cancelling:
            ProgressView()
                .scaleEffect(0.8)
        }
    }
}


// MARK: - Module Player Sheet
struct ModulePlayerSheet: View {
    let url: URL
    let title: String
    let moduleType: ModuleType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                switch moduleType {
                case .video:
                    VideoPlayer(player: AVPlayer(url: url))
                case .audio:
                    AudioPlayerView(url: url, title: title)
                case .document:
                    WebView(url: url)
                case .youtube:
                    WebView(url: url)
                case .scorm:
                    WebView(url: url)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Audio Player View
struct AudioPlayerView: View {
    let url: URL
    let title: String
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Album art placeholder
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 100))
                .foregroundColor(.purple)
            
            VStack(spacing: 8) {
                Text("Audio Player")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Text(url.lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Audio controls
            HStack(spacing: 40) {
                Button {
                    seekBackward()
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title)
                        .foregroundColor(.primary)
                }
                
                Button {
                    togglePlayPause()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primary)
                }
                
                Button {
                    seekForward()
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        player = AVPlayer(url: url)
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func seekBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTimeMakeWithSeconds(-15, preferredTimescale: 600))
        player.seek(to: newTime)
    }
    
    private func seekForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTimeMakeWithSeconds(15, preferredTimescale: 600))
        player.seek(to: newTime)
    }
}

// MARK: - Convenience Initializers
extension OnlineModuleButton {
    // Initialize with just URL
    init(url: String, title: String? = nil, moduleType: ModuleType = .document) {
        self.url = url
        self.courseId = nil
        self.title = title
        self.moduleType = moduleType
    }
    
    // Initialize with URL and courseId
    init(url: String, courseId: UUID, title: String? = nil, moduleType: ModuleType = .document) {
        self.url = url
        self.courseId = courseId
        self.title = title
        self.moduleType = moduleType
    }
}
