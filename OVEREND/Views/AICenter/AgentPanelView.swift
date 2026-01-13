//
//  AgentPanelView.swift
//  OVEREND
//
//  Agent 控制面板 - 顯示 Agent 狀態與執行任務
//

import SwiftUI
import CoreData

// MARK: - Agent 控制面板

/// Agent 控制面板視圖
@available(macOS 26.0, *)
struct AgentPanelView: View {
    
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var agent = LiteratureAgent.shared
    @ObservedObject var taskQueue = AgentTaskQueue()
    
    @State private var selectedEntries: [Entry] = []
    @State private var showingSuggestionSheet = false
    
    let library: Library
    let context: NSManagedObjectContext
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題區
            headerSection
            
            Divider()
            
            // 狀態區
            statusSection
            
            Divider()
            
            // 快速操作區
            quickActionsSection
            
            Divider()
            
            // 待處理建議區
            if !agent.pendingSuggestions.isEmpty {
                pendingSuggestionsSection
            }
            
            Spacer()
        }
        .background(theme.elevated)
        .sheet(isPresented: $showingSuggestionSheet) {
            SuggestionReviewSheet(
                suggestions: agent.pendingSuggestions,
                context: context,
                onApply: { suggestion in
                    try? agent.applySuggestion(suggestion, context: context)
                },
                onDismiss: {
                    showingSuggestionSheet = false
                }
            )
        }
    }
    
    // MARK: - 標題區
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "cpu")
                .font(.title2)
                .foregroundStyle(theme.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("AI 助理")
                    .font(.headline)
                    .foregroundStyle(theme.textPrimary)
                
                Text("自動整理、分類與標籤")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            
            Spacer()
            
            // 狀態指示燈
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
        .padding()
    }
    
    private var statusColor: Color {
        switch agent.state {
        case .idle:
            return .gray
        case .completed:
            return .green
        case .failed:
            return .red
        default:
            return .orange
        }
    }
    
    // MARK: - 狀態區
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("狀態")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                
                Spacer()
                
                Text(agent.state.statusText)
                    .font(.subheadline)
                    .foregroundStyle(agent.state.isExecuting ? theme.accent : theme.textPrimary)
            }
            
            if agent.state.isExecuting {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: agent.progress)
                        .progressViewStyle(.linear)
                        .tint(theme.accent)
                    
                    if !agent.progressMessage.isEmpty {
                        Text(agent.progressMessage)
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            
            if let result = agent.lastResult {
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.success ? .green : .red)
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
    }
    
    // MARK: - 快速操作區
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速操作")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                AgentActionButton(
                    icon: "folder.badge.gearshape",
                    title: "智慧分類",
                    description: "自動分類未整理文獻",
                    isLoading: agent.state == .classifying
                ) {
                    Task {
                        try? await agent.execute(task: .organizeByTopic(library))
                    }
                }
                
                AgentActionButton(
                    icon: "tag.fill",
                    title: "自動標籤",
                    description: "為文獻產生標籤",
                    isLoading: agent.state == .tagging
                ) {
                    Task {
                        let entries = Entry.fetchAll(in: library, context: context)
                        try? await agent.execute(task: .autoTagEntries(entries))
                    }
                }
                
                AgentActionButton(
                    icon: "doc.on.doc",
                    title: "尋找重複",
                    description: "檢測重複文獻",
                    isLoading: agent.state == .analyzing && agent.currentTask?.displayName == "尋找重複"
                ) {
                    Task {
                        try? await agent.execute(task: .findDuplicates(library))
                    }
                }
                
                AgentActionButton(
                    icon: "doc.plaintext",
                    title: "批次摘要",
                    description: "為缺少摘要的文獻生成",
                    isLoading: agent.state == .summarizing
                ) {
                    Task {
                        let entries = Entry.fetchAll(in: library, context: context)
                        try? await agent.execute(task: .generateSummaries(entries))
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - 待處理建議區
    
    private var pendingSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("待確認建議")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                
                Spacer()
                
                Text("\(agent.pendingSuggestions.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(theme.accent.opacity(0.2))
                    .foregroundStyle(theme.accent)
                    .clipShape(Capsule())
            }
            
            // 顯示前 3 個建議預覽
            ForEach(agent.pendingSuggestions.prefix(3)) { suggestion in
                SuggestionPreviewRow(suggestion: suggestion, theme: theme)
            }
            
            if agent.pendingSuggestions.count > 3 {
                Text("還有 \(agent.pendingSuggestions.count - 3) 個建議...")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            
            HStack {
                Button("檢視全部") {
                    showingSuggestionSheet = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("全部套用") {
                    applyAllSuggestions()
                }
                .buttonStyle(.borderedProminent)
                .disabled(agent.pendingSuggestions.isEmpty)
            }
        }
        .padding()
    }
    
    // MARK: - 方法
    
    private func applyAllSuggestions() {
        for suggestion in agent.pendingSuggestions {
            try? agent.applySuggestion(suggestion, context: context)
        }
    }
}

// MARK: - Agent 操作按鈕

@available(macOS 26.0, *)
struct AgentActionButton: View {
    
    let icon: String
    let title: String
    let description: String
    let isLoading: Bool
    let action: () -> Void
    
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: icon)
                            .font(.title2)
                    }
                }
                .frame(height: 28)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(theme.card)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - 建議預覽行

@available(macOS 26.0, *)
struct SuggestionPreviewRow: View {
    
    let suggestion: AgentSuggestion
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: suggestionIcon)
                .font(.caption)
                .foregroundStyle(suggestionColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.entry.title)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(theme.textPrimary)
                
                Text(suggestionDescription)
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
            }
            
            Spacer()
            
            Text("\(Int(suggestion.confidence * 100))%")
                .font(.caption2)
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.vertical, 4)
    }
    
    private var suggestionIcon: String {
        switch suggestion.type {
        case .group:
            return "folder.fill"
        case .tag:
            return "tag.fill"
        case .summary:
            return "doc.text.fill"
        case .duplicate:
            return "doc.on.doc.fill"
        }
    }
    
    private var suggestionColor: Color {
        switch suggestion.type {
        case .group:
            return .blue
        case .tag:
            return .green
        case .summary:
            return .orange
        case .duplicate:
            return .red
        }
    }
    
    private var suggestionDescription: String {
        switch suggestion.type {
        case .group(let name):
            return "建議分類：\(name)"
        case .tag(let name):
            return "建議標籤：\(name)"
        case .summary:
            return "建議摘要"
        case .duplicate(let other):
            return "與「\(other.title.prefix(20))...」重複"
        }
    }
}

// MARK: - 建議檢視表

@available(macOS 26.0, *)
struct SuggestionReviewSheet: View {
    
    let suggestions: [AgentSuggestion]
    let context: NSManagedObjectContext
    let onApply: (AgentSuggestion) -> Void
    let onDismiss: () -> Void
    
    @EnvironmentObject var theme: AppTheme
    @State private var selectedSuggestions: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Text("檢視 AI 建議")
                    .font(.headline)
                
                Spacer()
                
                Button("完成") {
                    onDismiss()
                }
            }
            .padding()
            
            Divider()
            
            // 建議列表
            List(suggestions) { suggestion in
                HStack {
                    Toggle("", isOn: Binding(
                        get: { selectedSuggestions.contains(suggestion.id) },
                        set: { isSelected in
                            if isSelected {
                                selectedSuggestions.insert(suggestion.id)
                            } else {
                                selectedSuggestions.remove(suggestion.id)
                            }
                        }
                    ))
                    .labelsHidden()
                    
                    SuggestionPreviewRow(suggestion: suggestion, theme: theme)
                    
                    Button("套用") {
                        onApply(suggestion)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            Divider()
            
            // 底部操作
            HStack {
                Button("全選") {
                    selectedSuggestions = Set(suggestions.map { $0.id })
                }
                
                Button("取消全選") {
                    selectedSuggestions.removeAll()
                }
                
                Spacer()
                
                Button("套用選中 (\(selectedSuggestions.count))") {
                    for suggestion in suggestions where selectedSuggestions.contains(suggestion.id) {
                        onApply(suggestion)
                    }
                    selectedSuggestions.removeAll()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedSuggestions.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - 預覽

#if DEBUG
@available(macOS 26.0, *)
struct AgentPanelView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let library = Library(context: context, name: "Preview")
        
        AgentPanelView(library: library, context: context)
            .environmentObject(AppTheme())
            .frame(width: 320, height: 600)
    }
}
#endif
