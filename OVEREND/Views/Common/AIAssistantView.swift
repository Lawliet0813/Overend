//
//  AIAssistantView.swift
//  OVEREND
//
//  AI 助手介面 - 使用 UnifiedAIService
//

import SwiftUI

/// AI 助手面板
@available(macOS 26.0, *)
struct AIAssistantView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = UnifiedAIService.shared
    
    @ObservedObject var entry: Entry
    
    @State private var summary: String = ""
    @State private var keywords: [String] = []
    @State private var suggestedCategories: [String] = []
    @State private var selectedAction: AIAction = .summary
    @State private var errorMessage: String?
    
    enum AIAction: String, CaseIterable {
        case summary = "摘要"
        case keywords = "關鍵詞"
        case category = "分類"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 16))
                        .foregroundColor(theme.accent)
                    Text("AI 助手")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                        .padding(4)
                        .background(Circle().fill(theme.itemHover))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(theme.toolbar)
            
            Divider()
            
            // Action Selection
            HStack(spacing: 8) {
                ForEach(AIAction.allCases, id: \.self) { action in
                    Button(action: { selectedAction = action }) {
                        Text(action.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule()
                                    .fill(selectedAction == action ? theme.accent.opacity(0.1) : Color.clear)
                            )
                            .foregroundColor(selectedAction == action ? theme.accent : theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    switch selectedAction {
                    case .summary:
                        summarySection
                    case .keywords:
                        keywordsSection
                    case .category:
                        categorySection
                    }
                }
                .padding()
            }
        }
        .frame(width: 320)
        .background(theme.sidebar)
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("文獻摘要")
                .font(.headline)
                .foregroundColor(theme.textSecondary)
            
            if !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textPrimary)
                    .textSelection(.enabled)
                    .padding()
                    .background(theme.card)
                    .cornerRadius(8)
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(summary, forType: .string)
                }) {
                    Label("複製摘要", systemImage: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.accent)
                
            } else if aiService.isProcessing {
                ProgressView("生成中...")
                    .frame(maxWidth: .infinity)
            } else {
                Button(action: generateSummary) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("生成摘要")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(theme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("關鍵詞提取")
                .font(.headline)
                .foregroundColor(theme.textSecondary)
            
            if !keywords.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(keywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.itemHover)
                            .cornerRadius(4)
                            .foregroundColor(theme.textPrimary)
                    }
                }
            } else if aiService.isProcessing {
                ProgressView("提取中...")
                    .frame(maxWidth: .infinity)
            } else {
                Button(action: extractKeywords) {
                    HStack {
                        Image(systemName: "tag")
                        Text("提取關鍵詞")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(theme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("智慧分類建議")
                .font(.headline)
                .foregroundColor(theme.textSecondary)
            
             if !suggestedCategories.isEmpty {
                ForEach(suggestedCategories, id: \.self) { category in
                    HStack {
                        Image(systemName: "folder")
                        Text(category)
                        Spacer()
                        Button(action: {
                            // TODO: Add to category
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                    .padding(8)
                    .background(theme.itemHover)
                    .cornerRadius(8)
                }
            } else if aiService.isProcessing {
                ProgressView("分析中...")
                    .frame(maxWidth: .infinity)
            } else {
                Button(action: suggestCategories) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("建議分類")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(theme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func generateSummary() {
        errorMessage = nil
        Task {
            do {
                summary = try await aiService.document.generateSummary(
                    title: entry.fields["title"] ?? "",
                    abstract: entry.fields["abstract"],
                    content: nil // TODO: Load PDF content if available
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func extractKeywords() {
        errorMessage = nil
        Task {
            do {
                keywords = try await aiService.document.extractKeywords(
                    title: entry.fields["title"] ?? "",
                    abstract: entry.fields["abstract"] ?? ""
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func suggestCategories() {
        errorMessage = nil
        Task {
            do {
                suggestedCategories = try await aiService.document.suggestCategories(
                    title: entry.fields["title"] ?? "",
                    abstract: entry.fields["abstract"] ?? "",
                    existingGroups: [] // TODO: Get existing groups
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
