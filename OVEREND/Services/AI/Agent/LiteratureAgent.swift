//
//  LiteratureAgent.swift
//  OVEREND
//
//  文獻 AI Agent - 自動化文獻整理、分類與標籤
//
//  提供智慧型文獻管理功能：
//  - 自動分析文獻內容
//  - 智慧分類建議
//  - 自動標籤生成
//  - 批次任務執行
//

import Foundation
import SwiftUI
import Combine
import CoreData
import PDFKit
import FoundationModels

// MARK: - Agent 任務類型

/// Agent 可執行的任務類型
public enum AgentTask: Identifiable, Equatable {
    case analyzeEntry(Entry)
    case classifyEntries([Entry])
    case autoTagEntries([Entry])
    case organizeByTopic(Library)
    case generateSummaries([Entry])
    case findDuplicates(Library)
    case batchProcess([Entry])
    case extractPDFMetadata(URL)  // 新增：PDF 元數據提取
    
    public var id: String {
        switch self {
        case .analyzeEntry(let entry):
            return "analyze-\(entry.id)"
        case .classifyEntries(let entries):
            return "classify-\(entries.count)"
        case .autoTagEntries(let entries):
            return "tag-\(entries.count)"
        case .organizeByTopic(let library):
            return "organize-\(library.id)"
        case .generateSummaries(let entries):
            return "summaries-\(entries.count)"
        case .findDuplicates(let library):
            return "duplicates-\(library.id)"
        case .batchProcess(let entries):
            return "batch-\(entries.count)"
        case .extractPDFMetadata(let url):
            return "pdf-\(url.lastPathComponent)"
        }
    }
    
    public var displayName: String {
        switch self {
        case .analyzeEntry:
            return "分析文獻"
        case .classifyEntries:
            return "智慧分類"
        case .autoTagEntries:
            return "自動標籤"
        case .organizeByTopic:
            return "主題整理"
        case .generateSummaries:
            return "生成摘要"
        case .findDuplicates:
            return "尋找重複"
        case .batchProcess:
            return "批次處理"
        case .extractPDFMetadata:
            return "PDF 提取"
        }
    }
    
    public var icon: String {
        switch self {
        case .analyzeEntry:
            return "doc.text.magnifyingglass"
        case .classifyEntries:
            return "folder.badge.gearshape"
        case .autoTagEntries:
            return "tag.fill"
        case .organizeByTopic:
            return "rectangle.3.group"
        case .generateSummaries:
            return "doc.plaintext"
        case .findDuplicates:
            return "doc.on.doc"
        case .batchProcess:
            return "square.stack.3d.up"
        case .extractPDFMetadata:
            return "doc.viewfinder"
        }
    }
    
    public static func == (lhs: AgentTask, rhs: AgentTask) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Agent 狀態

/// Agent 執行狀態
public enum AgentState: Equatable {
    case idle
    case analyzing
    case classifying
    case tagging
    case organizing
    case summarizing
    case completed
    case failed(String)
    
    public var isExecuting: Bool {
        switch self {
        case .idle, .completed, .failed:
            return false
        default:
            return true
        }
    }
    
    public var statusText: String {
        switch self {
        case .idle:
            return "準備就緒"
        case .analyzing:
            return "正在分析..."
        case .classifying:
            return "正在分類..."
        case .tagging:
            return "正在標籤..."
        case .organizing:
            return "正在整理..."
        case .summarizing:
            return "正在摘要..."
        case .completed:
            return "已完成"
        case .failed(let error):
            return "失敗：\(error)"
        }
    }
}

// MARK: - Agent 結果

/// Agent 執行結果
public struct AgentResult {
    public let task: AgentTask
    public let success: Bool
    public let message: String
    public let suggestions: [AgentSuggestion]
    public let duration: TimeInterval
    
    public init(
        task: AgentTask,
        success: Bool,
        message: String,
        suggestions: [AgentSuggestion] = [],
        duration: TimeInterval = 0
    ) {
        self.task = task
        self.success = success
        self.message = message
        self.suggestions = suggestions
        self.duration = duration
    }
}

/// Agent 建議
public struct AgentSuggestion: Identifiable {
    public let id = UUID()
    public let entry: Entry
    public let type: SuggestionType
    public let value: String
    public let confidence: Double
    
    public enum SuggestionType {
        case group(String)
        case tag(String)
        case summary(String)
        case duplicate(Entry)
    }
}

// MARK: - 文獻 Agent

/// 文獻 AI Agent
/// 
/// 提供自動化的文獻整理、分類與標籤功能
/// 
/// 使用方式：
/// ```swift
/// let agent = LiteratureAgent.shared
/// 
/// // 分析單篇文獻
/// let result = try await agent.execute(task: .analyzeEntry(entry))
/// 
/// // 批次分類
/// let suggestions = try await agent.classifyEntries(entries)
/// ```
@available(macOS 26.0, *)
@MainActor
public class LiteratureAgent: ObservableObject {
    
    // MARK: - 單例
    
    public static let shared = LiteratureAgent()
    
    // MARK: - 發布屬性
    
    /// 當前狀態
    @Published public var state: AgentState = .idle
    
    /// 當前任務
    @Published public var currentTask: AgentTask?
    
    /// 進度 (0.0 - 1.0)
    @Published public var progress: Double = 0
    
    /// 進度訊息
    @Published public var progressMessage: String = ""
    
    /// 最近的結果
    @Published public var lastResult: AgentResult?
    
    /// 待處理建議
    @Published public var pendingSuggestions: [AgentSuggestion] = []
    
    // MARK: - 私有屬性
    
    /// AI 服務 - 自動從 UnifiedAIService 取得
    private var aiService: UnifiedAIService {
        UnifiedAIService.shared
    }
    
    /// Adapter 管理器 - 取得 Custom Adapter Session
    private var adapterManager: AdapterManager {
        AdapterManager.shared
    }
    
    /// 是否使用 Custom Adapter（如果已載入）
    @Published public var useCustomAdapter: Bool = true
    
    private let taskQueue = AgentTaskQueue()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    private init() {
        AppLogger.shared.notice("🤖 LiteratureAgent: 初始化完成")
        
        // 檢查是否有可用的 Adapter
        if adapterManager.hasAdapter(.literature) {
            AppLogger.shared.notice("🔌 文獻專用 Adapter 已載入")
        }
    }
    
    // MARK: - Adapter Session
    
    /// 取得 Session（優先使用 Custom Adapter）
    private func getSession() -> LanguageModelSession {
        if useCustomAdapter && adapterManager.hasAdapter(.literature) {
            return adapterManager.createLiteratureSession()
        }
        return aiService.acquireSession()
    }
    
    // MARK: - 任務執行
    
    /// 執行指定任務
    public func execute(task: AgentTask) async throws -> AgentResult {
        let startTime = Date()
        currentTask = task
        progress = 0
        
        AppLogger.shared.info("🤖 Agent 開始任務: \(task.displayName)")
        
        do {
            let result: AgentResult
            
            switch task {
            case .analyzeEntry(let entry):
                state = .analyzing
                result = try await analyzeEntry(entry)
                
            case .classifyEntries(let entries):
                state = .classifying
                result = try await classifyEntriesTask(entries)
                
            case .autoTagEntries(let entries):
                state = .tagging
                result = try await autoTagEntriesTask(entries)
                
            case .organizeByTopic(let library):
                state = .organizing
                result = try await organizeByTopicTask(library)
                
            case .generateSummaries(let entries):
                state = .summarizing
                result = try await generateSummariesTask(entries)
                
            case .findDuplicates(let library):
                state = .analyzing
                result = try await findDuplicatesTask(library)
                
            case .batchProcess(let entries):
                result = try await batchProcessTask(entries)
                
            case .extractPDFMetadata(let url):
                state = .analyzing
                result = try await extractPDFMetadataTask(url)
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let finalResult = AgentResult(
                task: task,
                success: result.success,
                message: result.message,
                suggestions: result.suggestions,
                duration: duration
            )
            
            state = .completed
            lastResult = finalResult
            currentTask = nil
            progress = 1.0
            
            AppLogger.shared.notice("🤖 Agent 完成任務: \(task.displayName) (耗時: \(String(format: "%.1f", duration))s)")
            
            return finalResult
            
        } catch {
            state = .failed(error.localizedDescription)
            currentTask = nil
            
            AppLogger.shared.error("🤖 Agent 任務失敗: \(error.localizedDescription)")
            
            throw error
        }
    }
    
    // MARK: - 單篇分析
    
    private func analyzeEntry(_ entry: Entry) async throws -> AgentResult {
        progressMessage = "正在分析: \(entry.title)"
        
        // 取得文獻內容
        let title = entry.title
        let abstract = entry.fields["abstract"] ?? ""
        
        var suggestions: [AgentSuggestion] = []
        
        // 1. 提取關鍵詞
        progress = 0.3
        if let keywords = try? await aiService.document.extractKeywords(
            title: title,
            abstract: abstract
        ) {
            for keyword in keywords {
                suggestions.append(AgentSuggestion(
                    entry: entry,
                    type: .tag(keyword),
                    value: keyword,
                    confidence: 0.8
                ))
            }
        }
        
        // 2. 建議分類
        progress = 0.6
        if let categories = try? await aiService.document.suggestCategories(
            title: title,
            abstract: abstract,
            existingGroups: []
        ) {
            for category in categories {
                suggestions.append(AgentSuggestion(
                    entry: entry,
                    type: .group(category),
                    value: category,
                    confidence: 0.7
                ))
            }
        }
        
        // 3. 生成摘要（如果沒有摘要）
        progress = 0.9
        if abstract.isEmpty {
            if let summary = try? await aiService.document.generateSummary(
                title: title,
                abstract: nil,
                content: nil
            ) {
                suggestions.append(AgentSuggestion(
                    entry: entry,
                    type: .summary(summary),
                    value: summary,
                    confidence: 0.6
                ))
            }
        }
        
        pendingSuggestions.append(contentsOf: suggestions)
        
        return AgentResult(
            task: .analyzeEntry(entry),
            success: true,
            message: "分析完成，產生 \(suggestions.count) 個建議",
            suggestions: suggestions
        )
    }
    
    // MARK: - 批次分類
    
    private func classifyEntriesTask(_ entries: [Entry]) async throws -> AgentResult {
        var allSuggestions: [AgentSuggestion] = []
        
        for (index, entry) in entries.enumerated() {
            progress = Double(index) / Double(entries.count)
            progressMessage = "分類中 (\(index + 1)/\(entries.count)): \(entry.title.prefix(30))..."
            
            let title = entry.title
            let abstract = entry.fields["abstract"] ?? ""
            
            if let categories = try? await aiService.document.suggestCategories(
                title: title,
                abstract: abstract,
                existingGroups: []
            ) {
                for category in categories {
                    allSuggestions.append(AgentSuggestion(
                        entry: entry,
                        type: .group(category),
                        value: category,
                        confidence: 0.7
                    ))
                }
            }
        }
        
        pendingSuggestions.append(contentsOf: allSuggestions)
        
        return AgentResult(
            task: .classifyEntries(entries),
            success: true,
            message: "已為 \(entries.count) 篇文獻產生分類建議",
            suggestions: allSuggestions
        )
    }
    
    // MARK: - 自動標籤
    
    private func autoTagEntriesTask(_ entries: [Entry]) async throws -> AgentResult {
        var allSuggestions: [AgentSuggestion] = []
        
        for (index, entry) in entries.enumerated() {
            progress = Double(index) / Double(entries.count)
            progressMessage = "標籤中 (\(index + 1)/\(entries.count)): \(entry.title.prefix(30))..."
            
            let title = entry.title
            let abstract = entry.fields["abstract"] ?? ""
            
            if let keywords = try? await aiService.document.extractKeywords(
                title: title,
                abstract: abstract
            ) {
                for keyword in keywords {
                    allSuggestions.append(AgentSuggestion(
                        entry: entry,
                        type: .tag(keyword),
                        value: keyword,
                        confidence: 0.8
                    ))
                }
            }
        }
        
        pendingSuggestions.append(contentsOf: allSuggestions)
        
        return AgentResult(
            task: .autoTagEntries(entries),
            success: true,
            message: "已為 \(entries.count) 篇文獻產生標籤建議",
            suggestions: allSuggestions
        )
    }
    
    // MARK: - 主題整理
    
    private func organizeByTopicTask(_ library: Library) async throws -> AgentResult {
        // 取得所有未分類的文獻
        let context = PersistenceController.shared.container.viewContext
        let allEntries = Entry.fetchAll(in: library, context: context)
        let unclassified = allEntries.filter { ($0.groups?.isEmpty ?? true) }
        
        if unclassified.isEmpty {
            return AgentResult(
                task: .organizeByTopic(library),
                success: true,
                message: "所有文獻都已分類完成",
                suggestions: []
            )
        }
        
        // 批次分類
        return try await classifyEntriesTask(unclassified)
    }
    
    // MARK: - 生成摘要
    
    private func generateSummariesTask(_ entries: [Entry]) async throws -> AgentResult {
        var allSuggestions: [AgentSuggestion] = []
        
        // 只處理沒有摘要的文獻
        let entriesNeedingSummary = entries.filter { 
            ($0.fields["abstract"]?.isEmpty ?? true)
        }
        
        for (index, entry) in entriesNeedingSummary.enumerated() {
            progress = Double(index) / Double(entriesNeedingSummary.count)
            progressMessage = "生成摘要 (\(index + 1)/\(entriesNeedingSummary.count))"
            
            if let summary = try? await aiService.document.generateSummary(
                title: entry.title,
                abstract: nil,
                content: nil
            ) {
                allSuggestions.append(AgentSuggestion(
                    entry: entry,
                    type: .summary(summary),
                    value: summary,
                    confidence: 0.6
                ))
            }
        }
        
        pendingSuggestions.append(contentsOf: allSuggestions)
        
        return AgentResult(
            task: .generateSummaries(entries),
            success: true,
            message: "已為 \(allSuggestions.count) 篇文獻生成摘要",
            suggestions: allSuggestions
        )
    }
    
    // MARK: - 尋找重複
    
    private func findDuplicatesTask(_ library: Library) async throws -> AgentResult {
        let context = PersistenceController.shared.container.viewContext
        let allEntries = Entry.fetchAll(in: library, context: context)
        
        var duplicates: [AgentSuggestion] = []
        var checked = Set<UUID>()
        
        for entry in allEntries {
            if checked.contains(entry.id) { continue }
            
            for other in allEntries where other.id != entry.id {
                if checked.contains(other.id) { continue }
                
                // 簡單的標題相似度檢查
                if entry.title.lowercased() == other.title.lowercased() {
                    duplicates.append(AgentSuggestion(
                        entry: entry,
                        type: .duplicate(other),
                        value: "與「\(other.title)」重複",
                        confidence: 0.9
                    ))
                    checked.insert(other.id)
                }
            }
            
            checked.insert(entry.id)
            progress = Double(checked.count) / Double(allEntries.count)
        }
        
        return AgentResult(
            task: .findDuplicates(library),
            success: true,
            message: "找到 \(duplicates.count) 組重複文獻",
            suggestions: duplicates
        )
    }
    
    // MARK: - 批次處理
    
    private func batchProcessTask(_ entries: [Entry]) async throws -> AgentResult {
        var allSuggestions: [AgentSuggestion] = []
        
        // 1. 分類
        state = .classifying
        let classifyResult = try await classifyEntriesTask(entries)
        allSuggestions.append(contentsOf: classifyResult.suggestions)
        
        // 2. 標籤
        state = .tagging
        let tagResult = try await autoTagEntriesTask(entries)
        allSuggestions.append(contentsOf: tagResult.suggestions)
        
        return AgentResult(
            task: .batchProcess(entries),
            success: true,
            message: "批次處理完成，產生 \(allSuggestions.count) 個建議",
            suggestions: allSuggestions
        )
    }
    
    // MARK: - PDF 元數據提取
    
    /// PDF 提取結果（供外部使用）
    public struct PDFExtractionResult {
        public let title: String
        public let authors: [String]
        public let year: String?
        public let journal: String?
        public let doi: String?
        public let abstract: String?
        public let entryType: String
        public let confidence: Double
        
        /// 轉換為 Entry 欄位字典
        public var fields: [String: String] {
            var result: [String: String] = ["title": title]
            if !authors.isEmpty {
                result["author"] = authors.joined(separator: " and ")
            }
            if let year = year { result["year"] = year }
            if let journal = journal { result["journal"] = journal }
            if let doi = doi { result["doi"] = doi }
            if let abstract = abstract { result["abstract"] = abstract }
            return result
        }
    }
    
    /// 最近的 PDF 提取結果
    @Published public var lastExtractionResult: PDFExtractionResult?
    
    /// Agent 驅動的 PDF 元數據提取
    private func extractPDFMetadataTask(_ url: URL) async throws -> AgentResult {
        progressMessage = "正在分析 PDF: \(url.lastPathComponent)"
        
        // 1. 開啟 PDF 並提取文字
        progress = 0.1
        guard let document = PDFKit.PDFDocument(url: url) else {
            throw AgentError.taskFailed("無法開啟 PDF 文件")
        }
        
        // 提取前 3 頁文字
        var fullText = ""
        let maxPages = min(3, document.pageCount)
        for i in 0..<maxPages {
            if let page = document.page(at: i), let text = page.string {
                fullText += text + "\n"
            }
        }
        
        guard !fullText.isEmpty else {
            throw AgentError.taskFailed("無法從 PDF 提取文字")
        }
        
        progress = 0.3
        progressMessage = "使用 AI 分析元數據..."
        
        // 2. 使用 AI 分析元數據
        let session = getSession()
        
        let prompt = """
        請分析以下學術文獻文字，提取書目元數據。請以 JSON 格式回傳，包含以下欄位：
        - title: 標題
        - authors: 作者陣列
        - year: 出版年份
        - journal: 期刊名稱（如果是期刊論文）
        - doi: DOI（如果有）
        - entryType: 類型（article, book, thesis, conference, misc 等）
        - abstract: 摘要（如果有，限 300 字內）
        
        文獻內容（前 3 頁）：
        \(String(fullText.prefix(4000)))
        
        請只回傳 JSON，不要其他說明文字。
        """
        
        progress = 0.5
        
        do {
            let response = try await session.respond(to: prompt)
            let jsonString = response.content
            
            progress = 0.8
            progressMessage = "解析 AI 回應..."
            
            // 3. 解析 AI 回應
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let title = json["title"] as? String ?? url.deletingPathExtension().lastPathComponent
                let authors = json["authors"] as? [String] ?? []
                let year = json["year"] as? String
                let journal = json["journal"] as? String
                let doi = json["doi"] as? String
                let abstract = json["abstract"] as? String
                let entryType = json["entryType"] as? String ?? "misc"
                
                let result = PDFExtractionResult(
                    title: title,
                    authors: authors,
                    year: year,
                    journal: journal,
                    doi: doi,
                    abstract: abstract,
                    entryType: entryType,
                    confidence: 0.85
                )
                
                lastExtractionResult = result
                progress = 1.0
                
                return AgentResult(
                    task: .extractPDFMetadata(url),
                    success: true,
                    message: "成功提取元數據: \(title)",
                    suggestions: []
                )
            } else {
                // JSON 解析失敗，使用文件名降級
                let result = PDFExtractionResult(
                    title: url.deletingPathExtension().lastPathComponent,
                    authors: [],
                    year: nil,
                    journal: nil,
                    doi: nil,
                    abstract: nil,
                    entryType: "misc",
                    confidence: 0.3
                )
                
                lastExtractionResult = result
                
                return AgentResult(
                    task: .extractPDFMetadata(url),
                    success: true,
                    message: "AI 無法解析，使用文件名",
                    suggestions: []
                )
            }
            
        } catch {
            throw AgentError.taskFailed("AI 分析失敗: \(error.localizedDescription)")
        }
    }
    
    /// 便捷方法：使用 Agent 提取 PDF 元數據
    public func extractPDFMetadata(from url: URL) async throws -> PDFExtractionResult {
        let _ = try await execute(task: .extractPDFMetadata(url))
        guard let result = lastExtractionResult else {
            throw AgentError.taskFailed("無法取得提取結果")
        }
        return result
    }
    
    // MARK: - 便捷方法
    
    /// 快速分類文獻
    public func classifyEntries(_ entries: [Entry]) async throws -> [Entry: [String]] {
        let result = try await execute(task: .classifyEntries(entries))
        
        var grouped: [Entry: [String]] = [:]
        for suggestion in result.suggestions {
            if case .group(let name) = suggestion.type {
                if grouped[suggestion.entry] == nil {
                    grouped[suggestion.entry] = []
                }
                grouped[suggestion.entry]?.append(name)
            }
        }
        
        return grouped
    }
    
    /// 快速標籤文獻
    public func autoTagEntries(_ entries: [Entry]) async throws -> [Entry: [String]] {
        let result = try await execute(task: .autoTagEntries(entries))
        
        var grouped: [Entry: [String]] = [:]
        for suggestion in result.suggestions {
            if case .tag(let name) = suggestion.type {
                if grouped[suggestion.entry] == nil {
                    grouped[suggestion.entry] = []
                }
                grouped[suggestion.entry]?.append(name)
            }
        }
        
        return grouped
    }
    
    /// 套用建議
    public func applySuggestion(_ suggestion: AgentSuggestion, context: NSManagedObjectContext) throws {
        switch suggestion.type {
        case .group(let groupName):
            // 尋找或建立群組
            if let library = suggestion.entry.library {
                let existingGroups = Group.fetchRootGroups(in: library, context: context)
                if let group = existingGroups.first(where: { $0.name == groupName }) {
                    var entryGroups = suggestion.entry.groups ?? Set<Group>()
                    entryGroups.insert(group)
                    suggestion.entry.groups = entryGroups
                } else {
                    // 建立新群組
                    let newGroup = Group(context: context, name: groupName, library: library)
                    var entryGroups = suggestion.entry.groups ?? Set<Group>()
                    entryGroups.insert(newGroup)
                    suggestion.entry.groups = entryGroups
                }
            }
            
        case .tag(let tagName):
            if let library = suggestion.entry.library {
                let existingTags = Tag.fetchAll(in: library, context: context)
                if let tag = existingTags.first(where: { $0.name == tagName }) {
                    var entryTags = suggestion.entry.tags ?? Set<Tag>()
                    entryTags.insert(tag)
                    suggestion.entry.tags = entryTags
                } else {
                    // 建立新標籤
                    let newTag = Tag(context: context, name: tagName, library: library)
                    var entryTags = suggestion.entry.tags ?? Set<Tag>()
                    entryTags.insert(newTag)
                    suggestion.entry.tags = entryTags
                }
            }
            
        case .summary(let summary):
            var fields = suggestion.entry.fields
            fields["abstract"] = summary
            suggestion.entry.fields = fields
            
        case .duplicate:
            // 重複處理需要用戶確認，這裡只標記
            break
        }
        
        suggestion.entry.updatedAt = Date()
        try context.save()
        
        // 移除已套用的建議
        pendingSuggestions.removeAll { $0.id == suggestion.id }
    }
    
    /// 清除待處理建議
    public func clearPendingSuggestions() {
        pendingSuggestions.removeAll()
    }
    
    /// 重置狀態
    public func reset() {
        state = .idle
        currentTask = nil
        progress = 0
        progressMessage = ""
        lastResult = nil
    }
}

// MARK: - Agent 錯誤

/// Agent 錯誤類型
public enum AgentError: LocalizedError {
    case serviceNotAvailable
    case taskFailed(String)
    case noEntriesProvided
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .serviceNotAvailable:
            return "AI 服務不可用"
        case .taskFailed(let reason):
            return "任務失敗: \(reason)"
        case .noEntriesProvided:
            return "未提供文獻"
        case .cancelled:
            return "任務已取消"
        }
    }
}
