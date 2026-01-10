//
//  LiteratureQAView.swift
//  OVEREND
//
//  文獻問答視圖 - 與文獻對話，提取關鍵資訊
//

import SwiftUI
import CoreData
import FoundationModels

/// 對話訊息
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date
    let sources: [SourceReference]?
    
    enum Role: String {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
    }
}

/// 來源引用
struct SourceReference: Identifiable {
    let id = UUID()
    let title: String
    let authors: String
    let pageNumber: Int?
    let excerpt: String
}

/// 文獻問答視圖
@available(macOS 26.0, *)
struct LiteratureQAView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // 獲取所有文獻
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<Entry>
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var selectedEntries: Set<UUID> = []
    @State private var showEntryPicker: Bool = false
    
    // LearningService 整合
    @StateObject private var learningService = LearningService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具列
            toolbarView
            
            Divider()
            
            // 主內容
            HSplitView {
                // 對話區
                chatSection
                    .frame(minWidth: 400)
                
                // 文獻選擇區
                entrySelectorSection
                    .frame(width: 280)
            }
        }
        .background(theme.background)
        .onAppear {
            // 初始化歡迎訊息
            if messages.isEmpty {
                messages.append(ChatMessage(
                    role: .assistant,
                    content: "您好！我是文獻問答助手。請從右側選擇要查詢的文獻，然後輸入您的問題。\n\n例如：\n• 這篇論文的主要發現是什麼？\n• 作者使用了什麼研究方法？\n• 請摘要這篇文獻的核心論點",
                    timestamp: Date(),
                    sources: nil
                ))
            }
        }
    }
    
    // MARK: - 子視圖
    
    private var toolbarView: some View {
        HStack(spacing: 16) {
            // 標題
            HStack(spacing: 8) {
                Image(systemName: "message.badge.filled.fill")
                    .foregroundColor(theme.accent)
                Text("文獻問答")
                    .font(.headline)
            }
            
            Spacer()
            
            // 已選文獻數量
            if !selectedEntries.isEmpty {
                Text("\(selectedEntries.count) 篇文獻已選擇")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.accentLight)
                    .cornerRadius(4)
            }
            
            // 清空對話
            Button(action: clearChat) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .disabled(messages.count <= 1)
        }
        .padding()
        .background(theme.elevated)
    }
    
    private var chatSection: some View {
        VStack(spacing: 0) {
            // 訊息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            messageView(message)
                                .id(message.id)
                        }
                        
                        if isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("正在分析文獻...")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // 輸入區
            inputSection
        }
    }
    
    private func messageView(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // 訊息內容
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : theme.textPrimary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(message.role == .user ? theme.accent : theme.card)
                    )
                
                // 來源引用
                if let sources = message.sources, !sources.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("參考來源：")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                        
                        ForEach(sources) { source in
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.caption2)
                                Text(source.title)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundColor(theme.accent)
                        }
                    }
                    .padding(8)
                    .background(theme.elevated)
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: 500, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role != .user {
                Spacer()
            }
        }
    }
    
    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("輸入您的問題...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(12)
                .background(theme.card)
                .cornerRadius(12)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.isEmpty || selectedEntries.isEmpty ? theme.textTertiary : theme.accent)
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty || selectedEntries.isEmpty || isProcessing)
        }
        .padding()
        .background(theme.elevated)
    }
    
    private var entrySelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇文獻")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            Text("選擇要查詢的文獻（可多選）")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            // 搜尋欄
            TextField("搜尋文獻...", text: .constant(""))
                .textFieldStyle(.roundedBorder)
            
            // 文獻列表
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(entries) { entry in
                        entryRow(entry)
                    }
                }
            }
            
            // 快速選擇
            HStack {
                Button("全選") {
                    selectedEntries = Set(entries.compactMap { $0.id })
                }
                .font(.caption)
                
                Button("清除") {
                    selectedEntries.removeAll()
                }
                .font(.caption)
            }
        }
        .padding()
        .background(theme.elevated)
    }
    
    private func entryRow(_ entry: Entry) -> some View {
        let isSelected = selectedEntries.contains(entry.id)
        
        return HStack(spacing: 8) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? theme.accent : theme.textTertiary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(theme.textPrimary)
                
                Text(entry.author)
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(8)
        .background(isSelected ? theme.accentLight : theme.card)
        .cornerRadius(8)
        .onTapGesture {
            if isSelected {
                selectedEntries.remove(entry.id)
            } else {
                selectedEntries.insert(entry.id)
            }
        }
    }
    
    // MARK: - 方法
    
    private func sendMessage() {
        guard !inputText.isEmpty, !selectedEntries.isEmpty else { return }
        
        let userMessage = inputText
        inputText = ""
        
        // 添加使用者訊息
        messages.append(ChatMessage(
            role: .user,
            content: userMessage,
            timestamp: Date(),
            sources: nil
        ))
        
        isProcessing = true
        
        Task {
            let response = await generateResponse(for: userMessage)
            await MainActor.run {
                messages.append(response)
                isProcessing = false
                
                // ML 學習：記錄使用者問題類型
                learningService.learnTagging(title: userMessage, tags: ["QA", "文獻問答"])
            }
        }
    }
    
    private func generateResponse(for question: String) async -> ChatMessage {
        // 收集選中文獻的資訊
        let selectedLiteratures = entries.filter { selectedEntries.contains($0.id) }
        
        var context = "已選擇的文獻：\n"
        var sources: [SourceReference] = []
        
        for entry in selectedLiteratures {
            context += "- \(entry.title) (\(entry.author))\n"
            let noteText = entry.userNotes ?? ""
            if !noteText.isEmpty {
                context += "  備註：\(noteText.prefix(200))...\n"
            }
            
            sources.append(SourceReference(
                title: entry.title,
                authors: entry.author,
                pageNumber: nil,
                excerpt: entry.userNotes ?? ""
            ))
        }
        
        // 使用 AI 生成回答
        do {
            let ai = UnifiedAIService.shared
            let session = ai.acquireSession()
            defer { ai.releaseSession(session) }
            
            let prompt = """
            你是學術文獻問答助手。根據以下文獻資訊回答使用者的問題。
            
            \(context)
            
            使用者問題：\(question)
            
            請用繁體中文回答，並盡可能引用具體的文獻資訊。如果資訊不足，請誠實告知。
            """
            
            let response = try await session.respond(to: prompt)
            
            return ChatMessage(
                role: .assistant,
                content: response.content,
                timestamp: Date(),
                sources: sources
            )
        } catch {
            return ChatMessage(
                role: .assistant,
                content: "抱歉，處理您的問題時發生錯誤：\(error.localizedDescription)",
                timestamp: Date(),
                sources: nil
            )
        }
    }
    
    private func clearChat() {
        messages = [ChatMessage(
            role: .assistant,
            content: "對話已清空。請輸入您的新問題。",
            timestamp: Date(),
            sources: nil
        )]
    }
}
