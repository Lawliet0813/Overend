//
//  StandardsAIDomain.swift
//  OVEREND
//
//  規範檢查 AI 領域 - 整合所有規範檢查相關的 AI 功能
//
//  整合來源：
//  - TaiwanAcademicStandardsService
//

import Foundation
import FoundationModels

// MARK: - 規範問題類型

/// 規範問題類型
public enum StandardsIssueType: String, CaseIterable, Identifiable {
    case terminology = "terminology"    // 用語規範
    case citation = "citation"          // 引用格式
    case format = "format"              // 論文格式
    case style = "style"                // 行文風格
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .terminology: return "用語規範"
        case .citation: return "引用格式"
        case .format: return "論文格式"
        case .style: return "行文風格"
        }
    }
    
    public var icon: String {
        switch self {
        case .terminology: return "textformat"
        case .citation: return "quote.bubble"
        case .format: return "doc.text"
        case .style: return "pencil.line"
        }
    }
}

/// 問題嚴重程度
public enum StandardsSeverity: String, CaseIterable, Comparable {
    case error = "error"
    case warning = "warning"
    case suggestion = "suggestion"
    
    public var displayName: String {
        switch self {
        case .error: return "錯誤"
        case .warning: return "警告"
        case .suggestion: return "建議"
        }
    }
    
    public static func < (lhs: StandardsSeverity, rhs: StandardsSeverity) -> Bool {
        let order: [StandardsSeverity] = [.error, .warning, .suggestion]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - 規範問題

/// 規範問題
public struct StandardsIssue: Identifiable {
    public let id = UUID()
    public let type: StandardsIssueType
    public let severity: StandardsSeverity
    public let originalText: String?
    public let description: String
    public let suggestion: String?
    public let reference: String?
}

/// 規範檢查報告
public struct ComplianceReport {
    public let issues: [StandardsIssue]
    public let checkedAt: Date
    public let documentTitle: String?
    
    public var errorCount: Int {
        issues.filter { $0.severity == .error }.count
    }
    
    public var warningCount: Int {
        issues.filter { $0.severity == .warning }.count
    }
    
    public var suggestionCount: Int {
        issues.filter { $0.severity == .suggestion }.count
    }
    
    public var totalCount: Int {
        issues.count
    }
    
    public var isCompliant: Bool {
        errorCount == 0
    }
    
    public var issuesByType: [StandardsIssueType: [StandardsIssue]] {
        Dictionary(grouping: issues, by: { $0.type })
    }
}

// MARK: - 檢查選項

/// 規範檢查選項
public struct UnifiedStandardsCheckOptions {
    public var checkTerminology: Bool = true
    public var checkCitation: Bool = true
    public var checkFormat: Bool = true
    public var checkStyle: Bool = true
    public var citationStyle: CitationStyle = .apa7
    
    public init() {}
}

/// 文件類型
public enum DocumentType: String, CaseIterable {
    case thesis = "thesis"
    case journalArticle = "journal"
    case conference = "conference"
    case report = "report"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .thesis: return "碩博士論文"
        case .journalArticle: return "期刊論文"
        case .conference: return "研討會論文"
        case .report: return "報告"
        case .other: return "其他"
        }
    }
}

/// 待檢查文件
public struct CheckDocument {
    public let content: String
    public let title: String?
    public let documentType: DocumentType?
    
    public init(content: String, title: String? = nil, documentType: DocumentType? = nil) {
        self.content = content
        self.title = title
        self.documentType = documentType
    }
}

// MARK: - 規範檢查 AI 領域

/// 規範檢查 AI 領域
@available(macOS 26.0, *)
@MainActor
public class StandardsAIDomain {
    
    private weak var service: UnifiedAIService?
    
    init(service: UnifiedAIService) {
        self.service = service
    }
    
    // MARK: - 完整規範檢查
    
    /// 完整規範檢查
    /// - Parameters:
    ///   - document: 待檢查文件
    ///   - options: 檢查選項
    /// - Returns: 規範檢查報告
    public func checkCompliance(
        document: CheckDocument,
        options: UnifiedStandardsCheckOptions = UnifiedStandardsCheckOptions()
    ) async throws -> ComplianceReport {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !document.content.isEmpty else {
            throw AIServiceError.emptyDocument
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        var allIssues: [StandardsIssue] = []
        
        // 檢查用語規範
        if options.checkTerminology {
            let issues = try await checkTerminologyInternal(text: document.content)
            allIssues.append(contentsOf: issues)
        }
        
        // 檢查引用格式
        if options.checkCitation {
            let issues = try await checkCitationInternal(text: document.content, style: options.citationStyle)
            allIssues.append(contentsOf: issues)
        }
        
        // 檢查論文格式
        if options.checkFormat {
            let issues = try await checkFormatInternal(text: document.content, type: document.documentType)
            allIssues.append(contentsOf: issues)
        }
        
        // 檢查行文風格
        if options.checkStyle {
            let issues = try await checkStyleInternal(text: document.content)
            allIssues.append(contentsOf: issues)
        }
        
        // 依嚴重程度排序
        let sortedIssues = allIssues.sorted { $0.severity < $1.severity }
        
        return ComplianceReport(
            issues: sortedIssues,
            checkedAt: Date(),
            documentTitle: document.title
        )
    }
    
    // MARK: - 快速檢查
    
    /// 快速檢查（只檢查用語和風格）
    /// - Parameter text: 文字內容
    /// - Returns: 問題列表
    public func quickCheck(text: String) async throws -> [StandardsIssue] {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !text.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        var allIssues: [StandardsIssue] = []
        
        let terminologyIssues = try await checkTerminologyInternal(text: text)
        allIssues.append(contentsOf: terminologyIssues)
        
        let styleIssues = try await checkStyleInternal(text: text)
        allIssues.append(contentsOf: styleIssues)
        
        return allIssues.sorted { $0.severity < $1.severity }
    }
    
    // MARK: - 用語規範檢查
    
    /// 檢查用語規範
    /// - Parameter text: 文字內容
    /// - Returns: 用語問題列表
    public func checkTerminology(text: String) async throws -> [StandardsIssue] {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !text.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        return try await checkTerminologyInternal(text: text)
    }
    
    // MARK: - 私有檢查方法
    
    private func checkTerminologyInternal(text: String) async throws -> [StandardsIssue] {
        let session = service?.createSession() ?? LanguageModelSession()
        let truncatedText = String(text.prefix(4000))
        
        let prompt = """
        你是台灣學術規範專家。請檢查以下繁體中文學術文本的用語規範問題。
        
        文本：
        ---
        \(truncatedText)
        ---
        
        請檢查以下項目：
        1. 簡體中文用語（應使用繁體中文）
        2. 中國大陸學術用語（應使用台灣學術慣用語）
        3. 非正式口語（學術寫作應避免）
        
        常見需要修正的用語對照：
        - 信息 → 資訊
        - 視頻 → 影片
        - 軟件 → 軟體
        - 硬件 → 硬體
        - 數據 → 資料
        - 網絡 → 網路
        
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
        
        let response = try await session.respond(to: prompt)
        return try parseIssuesResponse(response.content, type: .terminology)
    }
    
    private func checkCitationInternal(text: String, style: CitationStyle) async throws -> [StandardsIssue] {
        let session = service?.createSession() ?? LanguageModelSession()
        let truncatedText = String(text.prefix(4000))
        
        let prompt = """
        請檢查以下文本的引用格式是否符合 \(style.displayName) 規範。
        
        文本：
        ---
        \(truncatedText)
        ---
        
        請檢查文內引用格式、作者姓名格式、年份格式等。
        
        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        [
          {
            "severity": "warning",
            "original": "原始引用",
            "description": "問題描述",
            "suggestion": "正確格式",
            "reference": "\(style.displayName) 引用規範"
          }
        ]
        
        如果沒有發現問題，回覆空陣列 []
        """
        
        let response = try await session.respond(to: prompt)
        return try parseIssuesResponse(response.content, type: .citation)
    }
    
    private func checkFormatInternal(text: String, type: DocumentType?) async throws -> [StandardsIssue] {
        let session = service?.createSession() ?? LanguageModelSession()
        let truncatedText = String(text.prefix(3000))
        
        var typeContext = ""
        if let docType = type {
            typeContext = "文件類型：\(docType.displayName)"
        }
        
        let prompt = """
        請檢查以下文本的格式問題。
        
        \(typeContext)
        
        文本：
        ---
        \(truncatedText)
        ---
        
        請檢查章節標題格式、段落格式、標點符號使用等。
        
        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        [
          {
            "severity": "suggestion",
            "original": "原始文字",
            "description": "問題描述",
            "suggestion": "修正建議",
            "reference": "論文格式規範"
          }
        ]
        
        如果沒有發現問題，回覆空陣列 []
        """
        
        let response = try await session.respond(to: prompt)
        return try parseIssuesResponse(response.content, type: .format)
    }
    
    private func checkStyleInternal(text: String) async throws -> [StandardsIssue] {
        let session = service?.createSession() ?? LanguageModelSession()
        let truncatedText = String(text.prefix(4000))
        
        let prompt = """
        請檢查以下繁體中文學術文本的行文風格問題。
        
        文本：
        ---
        \(truncatedText)
        ---
        
        請檢查：
        1. 第一人稱使用（應避免「我」、「我們」）
        2. 口語化表達
        3. 主觀判斷詞彙
        
        建議替換：
        - 我認為 → 本研究認為
        - 我們發現 → 研究發現
        
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
        
        如果沒有發現問題，回覆空陣列 []
        """
        
        let response = try await session.respond(to: prompt)
        return try parseIssuesResponse(response.content, type: .style)
    }
    
    // MARK: - 解析方法
    
    private func parseIssuesResponse(_ response: String, type: StandardsIssueType) throws -> [StandardsIssue] {
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let jsonStart = cleanedResponse.firstIndex(of: "["),
           let jsonEnd = cleanedResponse.lastIndex(of: "]") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        guard let data = cleanedResponse.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            if cleanedResponse.contains("[]") {
                return []
            }
            return []
        }
        
        return jsonArray.compactMap { dict -> StandardsIssue? in
            guard let description = dict["description"] as? String else { return nil }
            
            let severityStr = dict["severity"] as? String ?? "suggestion"
            let severity: StandardsSeverity
            switch severityStr {
            case "error": severity = .error
            case "warning": severity = .warning
            default: severity = .suggestion
            }
            
            return StandardsIssue(
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
