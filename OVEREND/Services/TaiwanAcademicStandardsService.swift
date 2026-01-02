//
//  TaiwanAcademicStandardsService.swift
//  OVEREND
//
//  台灣學術規範檢查服務 - 使用 Apple Foundation Models
//
//  檢查項目：
//  - 教育部繁中用語規範
//  - 台灣學術引用習慣
//  - 碩博士論文格式要求
//  - 學術行文風格
//

import Foundation
import SwiftUI
import Combine
import FoundationModels

// MARK: - 規範問題類型

/// 規範問題類型
enum ComplianceIssueType: String, CaseIterable, Identifiable {
    case terminology = "terminology"    // 用語規範
    case citation = "citation"          // 引用格式
    case format = "format"              // 論文格式
    case style = "style"                // 行文風格
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .terminology: return "用語規範"
        case .citation: return "引用格式"
        case .format: return "論文格式"
        case .style: return "行文風格"
        }
    }
    
    var icon: String {
        switch self {
        case .terminology: return "textformat"
        case .citation: return "quote.bubble"
        case .format: return "doc.text"
        case .style: return "pencil.line"
        }
    }
}

/// 問題嚴重程度
enum IssueSeverity: String, CaseIterable, Comparable {
    case error = "error"          // 錯誤（必須修正）
    case warning = "warning"      // 警告（建議修正）
    case suggestion = "suggestion" // 建議（可選修正）
    
    var displayName: String {
        switch self {
        case .error: return "錯誤"
        case .warning: return "警告"
        case .suggestion: return "建議"
        }
    }
    
    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .suggestion: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .suggestion: return "lightbulb.fill"
        }
    }
    
    // Comparable 實作
    static func < (lhs: IssueSeverity, rhs: IssueSeverity) -> Bool {
        let order: [IssueSeverity] = [.error, .warning, .suggestion]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - 規範問題

/// 規範問題
struct ComplianceIssue: Identifiable {
    let id: UUID
    let type: ComplianceIssueType
    let severity: IssueSeverity
    let location: NSRange?           // 問題位置
    let originalText: String?        // 原始文字
    let description: String          // 問題描述
    let suggestion: String?          // 修正建議
    let reference: String?           // 參考規範來源
    
    init(
        id: UUID = UUID(),
        type: ComplianceIssueType,
        severity: IssueSeverity,
        location: NSRange? = nil,
        originalText: String? = nil,
        description: String,
        suggestion: String? = nil,
        reference: String? = nil
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.location = location
        self.originalText = originalText
        self.description = description
        self.suggestion = suggestion
        self.reference = reference
    }
}

// MARK: - 文件結構

/// 待檢查的文件
struct AcademicDocument {
    let content: String
    let title: String?
    let metadata: DocumentMetadata?
    
    init(content: String, title: String? = nil, metadata: DocumentMetadata? = nil) {
        self.content = content
        self.title = title
        self.metadata = metadata
    }
    
    struct DocumentMetadata {
        var author: String?
        var institution: String?
        var documentType: DocumentType?
        var degree: DegreeType?
    }
    
    enum DocumentType: String, CaseIterable {
        case thesis = "thesis"              // 碩博士論文
        case journalArticle = "journal"     // 期刊論文
        case conference = "conference"      // 研討會論文
        case report = "report"              // 報告
        case other = "other"                // 其他
        
        var displayName: String {
            switch self {
            case .thesis: return "碩博士論文"
            case .journalArticle: return "期刊論文"
            case .conference: return "研討會論文"
            case .report: return "報告"
            case .other: return "其他"
            }
        }
    }
    
    enum DegreeType: String, CaseIterable {
        case master = "master"
        case doctoral = "doctoral"
        
        var displayName: String {
            switch self {
            case .master: return "碩士"
            case .doctoral: return "博士"
            }
        }
    }
}

// MARK: - 檢查選項

/// 檢查選項
struct StandardsCheckOptions {
    var checkTerminology: Bool = true      // 檢查用語規範
    var checkCitation: Bool = true         // 檢查引用格式
    var checkFormat: Bool = true           // 檢查論文格式
    var checkStyle: Bool = true            // 檢查行文風格
    var citationStyle: CitationStyle = .apa7  // 引用格式規範
    
    enum CitationStyle: String, CaseIterable {
        case apa7 = "apa7"           // APA 第七版
        case apa6 = "apa6"           // APA 第六版
        case chicago = "chicago"     // Chicago
        case mla = "mla"             // MLA
        
        var displayName: String {
            switch self {
            case .apa7: return "APA 第七版"
            case .apa6: return "APA 第六版"
            case .chicago: return "Chicago"
            case .mla: return "MLA"
            }
        }
    }
}

// MARK: - 檢查結果

/// 檢查結果摘要
struct StandardsCheckResult {
    let issues: [ComplianceIssue]
    let checkedAt: Date
    let documentTitle: String?
    
    var errorCount: Int {
        issues.filter { $0.severity == .error }.count
    }
    
    var warningCount: Int {
        issues.filter { $0.severity == .warning }.count
    }
    
    var suggestionCount: Int {
        issues.filter { $0.severity == .suggestion }.count
    }
    
    var totalCount: Int {
        issues.count
    }
    
    var issuesByType: [ComplianceIssueType: [ComplianceIssue]] {
        Dictionary(grouping: issues, by: { $0.type })
    }
    
    var issuesBySeverity: [IssueSeverity: [ComplianceIssue]] {
        Dictionary(grouping: issues, by: { $0.severity })
    }
    
    var isCompliant: Bool {
        errorCount == 0
    }
}

// MARK: - 台灣學術規範服務

/// 台灣學術規範檢查服務 - 使用 Apple Foundation Models
@available(macOS 26.0, *)
@MainActor
class TaiwanAcademicStandardsService: ObservableObject {
    
    static let shared = TaiwanAcademicStandardsService()
    
    // MARK: - 狀態
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0
    @Published var currentCheckType: ComplianceIssueType?
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - 規範檢查
    
    /// 檢查台灣學術規範
    /// - Parameter document: 待檢查的文件
    /// - Returns: 規範問題列表
    func checkTaiwanAcademicStandards(
        document: AcademicDocument
    ) async throws -> [ComplianceIssue] {
        return try await checkTaiwanAcademicStandards(
            document: document,
            options: StandardsCheckOptions()
        )
    }
    
    /// 檢查台灣學術規範（帶選項）
    /// - Parameters:
    ///   - document: 待檢查的文件
    ///   - options: 檢查選項
    /// - Returns: 規範問題列表
    func checkTaiwanAcademicStandards(
        document: AcademicDocument,
        options: StandardsCheckOptions
    ) async throws -> [ComplianceIssue] {
        guard !document.content.isEmpty else {
            throw StandardsCheckError.emptyDocument
        }
        
        isProcessing = true
        progress = 0
        defer { 
            isProcessing = false 
            progress = 1.0
            currentCheckType = nil
        }
        
        var allIssues: [ComplianceIssue] = []
        let totalSteps = [options.checkTerminology, options.checkCitation, options.checkFormat, options.checkStyle].filter { $0 }.count
        var completedSteps = 0
        
        // 1. 檢查用語規範
        if options.checkTerminology {
            currentCheckType = .terminology
            let terminologyIssues = try await checkTerminology(document: document)
            allIssues.append(contentsOf: terminologyIssues)
            completedSteps += 1
            progress = Double(completedSteps) / Double(totalSteps)
        }
        
        // 2. 檢查引用格式
        if options.checkCitation {
            currentCheckType = .citation
            let citationIssues = try await checkCitation(document: document, style: options.citationStyle)
            allIssues.append(contentsOf: citationIssues)
            completedSteps += 1
            progress = Double(completedSteps) / Double(totalSteps)
        }
        
        // 3. 檢查論文格式
        if options.checkFormat {
            currentCheckType = .format
            let formatIssues = try await checkFormat(document: document)
            allIssues.append(contentsOf: formatIssues)
            completedSteps += 1
            progress = Double(completedSteps) / Double(totalSteps)
        }
        
        // 4. 檢查行文風格
        if options.checkStyle {
            currentCheckType = .style
            let styleIssues = try await checkStyle(document: document)
            allIssues.append(contentsOf: styleIssues)
            completedSteps += 1
            progress = Double(completedSteps) / Double(totalSteps)
        }
        
        // 依嚴重程度排序
        return allIssues.sorted { $0.severity < $1.severity }
    }
    
    /// 快速檢查（只檢查最重要的項目）
    func quickCheck(text: String) async throws -> [ComplianceIssue] {
        let document = AcademicDocument(content: text)
        var options = StandardsCheckOptions()
        options.checkFormat = false  // 快速檢查不檢查格式
        return try await checkTaiwanAcademicStandards(document: document, options: options)
    }
    
    // MARK: - 個別檢查項目
    
    /// 檢查用語規範
    private func checkTerminology(document: AcademicDocument) async throws -> [ComplianceIssue] {
        let session = LanguageModelSession()
        
        // 截取適當長度的文字
        let truncatedContent = String(document.content.prefix(4000))
        
        let prompt = """
        你是台灣學術規範專家。請檢查以下繁體中文學術文本的用語規範問題。
        
        文本：
        ---
        \(truncatedContent)
        ---
        
        請檢查以下項目：
        1. 簡體中文用語（應使用繁體中文）
        2. 中國大陸學術用語（應使用台灣學術慣用語）
        3. 非正式口語（學術寫作應避免）
        4. 第一人稱過度使用（學術寫作應減少）
        5. 教育部規範術語
        
        常見需要修正的用語對照：
        - 信息 → 資訊
        - 視頻 → 影片
        - 軟件 → 軟體
        - 硬件 → 硬體
        - 數據 → 資料
        - 網絡 → 網路
        - 博客 → 部落格
        - 激活 → 啟動
        - 支持 → 支援
        
        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        [
          {
            "severity": "warning",
            "original": "原始文字",
            "description": "問題描述",
            "suggestion": "修正建議",
            "reference": "教育部國語推行委員會"
          }
        ]
        
        severity 可選值：error, warning, suggestion
        如果沒有發現問題，回覆空陣列 []
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseIssuesResponse(response.content, type: .terminology)
        } catch let error as StandardsCheckError {
            throw error
        } catch {
            throw StandardsCheckError.checkFailed(error.localizedDescription)
        }
    }
    
    /// 檢查引用格式
    private func checkCitation(
        document: AcademicDocument,
        style: StandardsCheckOptions.CitationStyle
    ) async throws -> [ComplianceIssue] {
        let session = LanguageModelSession()
        
        let truncatedContent = String(document.content.prefix(4000))
        
        let prompt = """
        你是台灣學術引用格式專家。請檢查以下文本的引用格式是否符合 \(style.displayName) 規範。
        
        文本：
        ---
        \(truncatedContent)
        ---
        
        請檢查以下項目：
        1. 文內引用格式（作者-年份格式）
        2. 中文作者姓名格式（姓在前、名在後）
        3. 英文作者姓名格式（姓, 名縮寫）
        4. 多作者引用格式（et al. / 等人 的使用）
        5. 年份格式（西元年）
        6. 頁碼引用格式
        
        台灣 \(style.displayName) 特別注意事項：
        - 中文引用使用全形標點
        - 英文引用使用半形標點
        - "et al." 用於英文，"等人" 用於中文
        - 台灣學術習慣：先列中文文獻，再列英文文獻
        
        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        [
          {
            "severity": "warning",
            "original": "原始引用文字",
            "description": "問題描述",
            "suggestion": "正確格式",
            "reference": "\(style.displayName) 引用規範"
          }
        ]
        
        severity 可選值：error, warning, suggestion
        如果沒有發現問題，回覆空陣列 []
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseIssuesResponse(response.content, type: .citation)
        } catch let error as StandardsCheckError {
            throw error
        } catch {
            throw StandardsCheckError.checkFailed(error.localizedDescription)
        }
    }
    
    /// 檢查論文格式
    private func checkFormat(document: AcademicDocument) async throws -> [ComplianceIssue] {
        let session = LanguageModelSession()
        
        let truncatedContent = String(document.content.prefix(3000))
        
        var documentTypeContext = ""
        if let docType = document.metadata?.documentType {
            documentTypeContext = "文件類型：\(docType.displayName)"
            if docType == .thesis, let degree = document.metadata?.degree {
                documentTypeContext += "（\(degree.displayName)論文）"
            }
        }
        
        let prompt = """
        你是台灣碩博士論文格式專家。請檢查以下文本的格式問題。
        
        \(documentTypeContext)
        
        文本：
        ---
        \(truncatedContent)
        ---
        
        請檢查以下項目（根據台灣碩博士論文格式規範）：
        1. 章節標題格式（第一章、第一節等）
        2. 段落首行縮排
        3. 標點符號使用（全形/半形）
        4. 數字格式（阿拉伯數字 vs 中文數字）
        5. 專有名詞首次出現時是否加註英文
        
        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        [
          {
            "severity": "suggestion",
            "original": "原始文字",
            "description": "問題描述",
            "suggestion": "修正建議",
            "reference": "台灣碩博士論文格式規範"
          }
        ]
        
        severity 可選值：error, warning, suggestion
        如果沒有發現問題，回覆空陣列 []
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseIssuesResponse(response.content, type: .format)
        } catch let error as StandardsCheckError {
            throw error
        } catch {
            throw StandardsCheckError.checkFailed(error.localizedDescription)
        }
    }
    
    /// 檢查行文風格
    private func checkStyle(document: AcademicDocument) async throws -> [ComplianceIssue] {
        let session = LanguageModelSession()
        
        let truncatedContent = String(document.content.prefix(4000))
        
        let prompt = """
        你是學術寫作風格專家。請檢查以下繁體中文學術文本的行文風格問題。
        
        文本：
        ---
        \(truncatedContent)
        ---
        
        請檢查以下項目：
        1. 第一人稱使用（學術寫作應避免「我」、「我們」）
        2. 口語化表達（應使用正式書面語）
        3. 主觀判斷詞彙（如「很好」、「很棒」應改為客觀描述）
        4. 冗贅表達（可以精簡的句子）
        5. 邏輯連接詞使用（是否適當使用「因此」、「然而」、「綜上所述」等）
        6. 學術嚴謹性（避免過度推論、絕對化陳述）
        
        建議的學術表達替換：
        - 我認為 → 本研究認為 / 研究者認為
        - 我們發現 → 研究發現 / 結果顯示
        - 很明顯 → 由此可見 / 顯示
        - 大家都知道 → 普遍認為 / 學界共識
        
        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        [
          {
            "severity": "suggestion",
            "original": "原始文字",
            "description": "問題描述",
            "suggestion": "修正建議",
            "reference": "學術寫作規範"
          }
        ]
        
        severity 可選值：error, warning, suggestion
        如果沒有發現問題，回覆空陣列 []
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseIssuesResponse(response.content, type: .style)
        } catch let error as StandardsCheckError {
            throw error
        } catch {
            throw StandardsCheckError.checkFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 私有方法
    
    /// 解析問題回應
    private func parseIssuesResponse(
        _ response: String,
        type: ComplianceIssueType
    ) throws -> [ComplianceIssue] {
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 提取 JSON 陣列
        if let jsonStart = cleanedResponse.firstIndex(of: "["),
           let jsonEnd = cleanedResponse.lastIndex(of: "]") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        guard let data = cleanedResponse.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            // 如果解析失敗但內容看起來是空的，返回空陣列
            if cleanedResponse.contains("[]") || cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return []
            }
            throw StandardsCheckError.parseError
        }
        
        return jsonArray.compactMap { dict -> ComplianceIssue? in
            guard let description = dict["description"] as? String else { return nil }
            
            let severityString = dict["severity"] as? String ?? "suggestion"
            let severity: IssueSeverity
            switch severityString {
            case "error": severity = .error
            case "warning": severity = .warning
            default: severity = .suggestion
            }
            
            return ComplianceIssue(
                type: type,
                severity: severity,
                originalText: dict["original"] as? String,
                description: description,
                suggestion: dict["suggestion"] as? String,
                reference: dict["reference"] as? String
            )
        }
    }
}

// MARK: - 錯誤類型

/// 規範檢查錯誤
enum StandardsCheckError: LocalizedError {
    case emptyDocument
    case checkFailed(String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .emptyDocument:
            return "請輸入要檢查的文件內容"
        case .checkFailed(let message):
            return "規範檢查失敗：\(message)"
        case .parseError:
            return "無法解析檢查結果"
        }
    }
}
