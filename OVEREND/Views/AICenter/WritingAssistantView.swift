//
//  WritingAssistantView.swift
//  OVEREND
//
//  寫作 AI 助手面板 - 使用者主動呼叫 AI 協助
//
//  核心功能：
//  - 預設關閉，使用者手動開啟
//  - 根據當前章節提供針對性建議
//  - 分析文獻庫建議補充方向
//

import SwiftUI
import CoreData
import FoundationModels

// MARK: - 助手模式

/// 寫作助手模式
public enum WritingAssistantMode: String, CaseIterable, Identifiable {
    case sectionHelp = "章節建議"
    case literatureGap = "文獻分析"
    case outlinePlanner = "架構規劃"
    case freeChat = "自由提問"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .sectionHelp: return "text.badge.star"
        case .literatureGap: return "books.vertical.fill"
        case .outlinePlanner: return "list.bullet.rectangle"
        case .freeChat: return "bubble.left.and.bubble.right"
        }
    }
    
    public var description: String {
        switch self {
        case .sectionHelp: return "根據當前章節提供寫作建議"
        case .literatureGap: return "分析文獻庫，建議補充方向"
        case .outlinePlanner: return "輸入主題，生成架構大綱"
        case .freeChat: return "自由提問任何寫作問題"
        }
    }
}

// MARK: - 寫作助手視圖

/// 寫作 AI 助手側邊面板
@available(macOS 26.0, *)
struct WritingAssistantView: View {
    
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - 狀態
    
    /// 當前助手模式
    @State private var mode: WritingAssistantMode = .sectionHelp
    
    /// 使用者輸入
    @State private var userInput: String = ""
    
    /// AI 回應
    @State private var aiResponse: String = ""
    
    /// 是否正在處理
    @State private var isProcessing: Bool = false
    
    /// 當前偵測到的章節
    @StateObject private var sectionDetector = SectionDetector.shared
    
    /// AI 服務
    private let aiService = UnifiedAIService.shared
    
    // MARK: - 綁定
    
    /// 當前文件文字（從編輯器傳入）
    var documentText: String
    
    /// 游標位置
    @Binding var cursorPosition: Int
    
    /// 是否顯示助手面板
    @Binding var isPresented: Bool
    
    /// 選中的文獻庫
    var selectedLibrary: Library?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            headerView
            
            Divider()
            
            // 模式選擇器
            modeSelector
            
            Divider()
            
            // 主內容區
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch mode {
                    case .sectionHelp:
                        sectionHelpContent
                    case .literatureGap:
                        literatureGapContent
                    case .outlinePlanner:
                        outlinePlannerContent
                    case .freeChat:
                        freeChatContent
                    }
                    
                    // AI 回應區
                    if !aiResponse.isEmpty {
                        aiResponseSection
                    }
                }
                .padding()
            }
            
            Divider()
            
            // 輸入區
            inputSection
        }
        .frame(width: 320)
        .background(theme.sidebar)
        .onAppear {
            detectCurrentSection()
        }
        .onChange(of: cursorPosition) { _, _ in
            detectCurrentSection()
        }
    }
    
    // MARK: - 子視圖
    
    private var headerView: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(theme.accent)
            
            Text("AI 寫作助手")
                .font(.headline)
            
            Spacer()
            
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private var modeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WritingAssistantMode.allCases) { m in
                    Button {
                        mode = m
                        aiResponse = ""
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: m.icon)
                            Text(m.rawValue)
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(mode == m ? theme.accent : theme.elevated)
                        .foregroundStyle(mode == m ? .white : theme.textPrimary)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 章節建議內容
    
    private var sectionHelpContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 當前章節顯示
            HStack {
                Image(systemName: sectionDetector.currentSection.icon)
                    .foregroundStyle(theme.accent)
                
                Text("目前章節：\(sectionDetector.currentSection.rawValue)")
                    .font(.subheadline.bold())
                
                if sectionDetector.confidence > 0.7 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            
            // 寫作提示
            VStack(alignment: .leading, spacing: 8) {
                Text("寫作提示")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                
                ForEach(sectionDetector.currentSection.writingHints, id: \.self) { hint in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(theme.textPrimary)
                    }
                }
            }
            .padding()
            .background(theme.elevated)
            .cornerRadius(8)
            
            // 快速提問按鈕
            Text("快速提問")
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                QuickPromptButton(text: "如何開頭？") {
                    askAI("我正在寫\(sectionDetector.currentSection.rawValue)，請建議幾種開頭方式")
                }
                
                QuickPromptButton(text: "常見問題") {
                    askAI("寫\(sectionDetector.currentSection.rawValue)時常見的問題有哪些？")
                }
                
                QuickPromptButton(text: "銜接技巧") {
                    askAI("如何讓\(sectionDetector.currentSection.rawValue)與下一章節銜接順暢？")
                }
                
                QuickPromptButton(text: "檢查清單") {
                    askAI("請給我一份\(sectionDetector.currentSection.rawValue)的自我檢查清單")
                }
            }
        }
    }
    
    // MARK: - 文獻分析內容
    
    private var literatureGapContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let library = selectedLibrary {
                Text("文獻庫：\(library.name)")
                    .font(.subheadline.bold())
                
                Button {
                    analyzeLiteratureGap(library: library)
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass.circle.fill")
                        Text("分析文獻缺口")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(theme.textSecondary)
                    
                    Text("請先選擇文獻庫")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
    }
    
    // MARK: - 架構規劃內容
    
    private var outlinePlannerContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("輸入您想寫的主題，AI 會幫您規劃架構")
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            
            // 寫作類型選擇
            HStack(spacing: 8) {
                WritingTypeButton(icon: "book", label: "論文")
                WritingTypeButton(icon: "doc.text", label: "報告")
                WritingTypeButton(icon: "rectangle.and.pencil.and.ellipsis", label: "部落格")
            }
            
            Text("範例：「探討社群媒體對青少年心理健康的影響」")
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
                .italic()
        }
    }
    
    // MARK: - 自由提問內容
    
    private var freeChatContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("自由提問任何寫作相關問題")
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            
            // 建議提問
            VStack(alignment: .leading, spacing: 8) {
                Text("建議提問")
                    .font(.caption.bold())
                    .foregroundStyle(theme.textSecondary)
                
                ForEach(["如何避免學術抄襲？", "APA 格式的基本規則？", "如何寫出有力的論點？"], id: \.self) { suggestion in
                    Button {
                        userInput = suggestion
                    } label: {
                        Text(suggestion)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(theme.elevated)
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - AI 回應區
    
    private var aiResponseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(theme.accent)
                Text("AI 建議")
                    .font(.caption.bold())
                Spacer()
                
                Button {
                    copyToClipboard(aiResponse)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
            }
            
            Text(aiResponse)
                .font(.body)
                .foregroundStyle(theme.textPrimary)
                .textSelection(.enabled)
        }
        .padding()
        .background(theme.elevated)
        .cornerRadius(8)
    }
    
    // MARK: - 輸入區
    
    private var inputSection: some View {
        HStack(spacing: 8) {
            TextField("輸入您的問題...", text: $userInput, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...3)
                .padding(8)
                .background(theme.elevated)
                .cornerRadius(8)
            
            Button {
                askAI(userInput)
            } label: {
                Image(systemName: isProcessing ? "hourglass" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
            .disabled(userInput.isEmpty || isProcessing)
        }
        .padding()
    }
    
    // MARK: - 方法
    
    /// 偵測當前章節
    private func detectCurrentSection() {
        _ = sectionDetector.detectSection(text: documentText, cursorPosition: cursorPosition)
    }
    
    /// 向 AI 提問
    private func askAI(_ question: String) {
        guard !question.isEmpty else { return }
        
        isProcessing = true
        let promptText = question
        userInput = ""
        
        Task {
            do {
                let session = aiService.acquireSession()
                let response = try await session.respond(to: promptText)
                
                await MainActor.run {
                    aiResponse = response.content
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    aiResponse = "抱歉，發生錯誤：\(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
    
    /// 分析文獻缺口
    private func analyzeLiteratureGap(library: Library) {
        isProcessing = true
        
        let entries = Entry.fetchAll(in: library, context: viewContext)
        let titles = entries.map { $0.title }.joined(separator: "\n")
        
        let prompt = """
        我有以下文獻：
        \(titles)
        
        請分析這些文獻涵蓋的主題，並建議可能需要補充的研究方向或遺漏的觀點。
        """
        
        Task {
            do {
                let session = aiService.acquireSession()
                let response = try await session.respond(to: prompt)
                
                await MainActor.run {
                    aiResponse = response.content
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    aiResponse = "分析失敗：\(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
    
    /// 複製到剪貼簿
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - 輔助視圖

struct QuickPromptButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct WritingTypeButton: View {
    let icon: String
    let label: String
    @State private var isSelected = false
    
    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
