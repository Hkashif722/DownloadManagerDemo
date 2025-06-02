//
//  OnlineModuleDemoView.swift
//  DownloadManagerDemo
//
//  Created by Kashif Hussain on 02/06/25.
//


//
//  OnlineModuleDemoView.swift
//  DownloadManagerDemo
//
//  Demo view showcasing OnlineModuleButton functionality
//

import SwiftUI
import DownloadManager

// MARK: - Online Module Demo View
struct OnlineModuleDemoView: View {
    @State private var customURL = ""
    @State private var customTitle = ""
    @State private var selectedModuleType: ModuleType = .document
    @State private var showingCustomModule = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "globe.badge.chevron.down")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Online Module Downloads")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Download and manage online content with ease")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Sample modules section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Sample Modules", icon: "doc.text.fill")
                        
                        // Document sample
                        OnlineModuleButton(
                            url: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                            title: "W3C Sample PDF Document",
                            moduleType: .document
                        )
                        
                        // Video sample
                        OnlineModuleButton(
                            url: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4",
                            title: "Big Buck Bunny - Sample Video",
                            moduleType: .video
                        )
                        
                        // Audio sample
                        OnlineModuleButton(
                            url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
                            title: "SoundHelix - Sample Audio Track",
                            moduleType: .audio
                        )
                        
                        // YouTube sample
                        OnlineModuleButton(
                            url: "https://youtube.com/watch?v=dQw4w9WgXcQ",
                            title: "YouTube Video Sample",
                            moduleType: .youtube
                        )
                        
                        // SCORM sample
                        OnlineModuleButton(
                            url: "https://github.com/ADL-AICC/SCORM-2004-4ed-Test-Suite/archive/master.zip",
                            title: "SCORM Test Package",
                            moduleType: .scorm
                        )
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Custom URL section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Add Custom Module", icon: "plus.circle.fill")
                        
                        CustomModuleForm(
                            customURL: $customURL,
                            customTitle: $customTitle,
                            selectedModuleType: $selectedModuleType,
                            showingCustomModule: $showingCustomModule
                        )
                        
                        if showingCustomModule && !customURL.isEmpty {
                            OnlineModuleButton(
                                url: customURL,
                                title: customTitle.isEmpty ? "Custom Module" : customTitle,
                                moduleType: selectedModuleType
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Feature overview
                    FeatureOverviewSection()
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Online Modules")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

// MARK: - Custom Module Form
struct CustomModuleForm: View {
    @Binding var customURL: String
    @Binding var customTitle: String
    @Binding var selectedModuleType: ModuleType
    @Binding var showingCustomModule: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // URL input
            VStack(alignment: .leading, spacing: 4) {
                Text("URL")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter module URL", text: $customURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            // Title input
            VStack(alignment: .leading, spacing: 4) {
                Text("Title (Optional)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter module title", text: $customTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Module type picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Module Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Module Type", selection: $selectedModuleType) {
                    ForEach(ModuleType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: iconForModuleType(type))
                            Text(type.rawValue)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Add button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingCustomModule = true
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Module")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.blue)
                .cornerRadius(8)
            }
            .disabled(customURL.isEmpty)
            
            // Clear button
            if showingCustomModule {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        customURL = ""
                        customTitle = ""
                        selectedModuleType = .document
                        showingCustomModule = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.red)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
}

// MARK: - Feature Overview Section
struct FeatureOverviewSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Features", icon: "star.fill")
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "arrow.down.circle.fill",
                    title: "Smart Downloads",
                    description: "Resume interrupted downloads and manage concurrent downloads"
                )
                
                FeatureRow(
                    icon: "play.circle.fill",
                    title: "Integrated Player",
                    description: "Play videos, audio, and view documents without leaving the app"
                )
                
                FeatureRow(
                    icon: "icloud.and.arrow.down.fill",
                    title: "Offline Access",
                    description: "Access downloaded content even when offline"
                )
                
                FeatureRow(
                    icon: "gear.circle.fill",
                    title: "Multiple Formats",
                    description: "Support for documents, videos, audio, YouTube, and SCORM packages"
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    OnlineModuleDemoView()
}
