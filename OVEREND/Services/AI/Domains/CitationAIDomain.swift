//
//  CitationAIDomain.swift
//  OVEREND
//
//  引用 AI 領域 - 整合所有引用格式相關的 AI 功能
//
//  整合來源：
//  - AILayoutFormatter.fixCitations()
//  - TaiwanAcademicStandardsService.checkCitation()
//  - AICommandExecutor 引用相關指令
//

import Foundation
import AppKit
import FoundationModels

// MARK: - 引用格式

/// 引用格式樣式
public enum CitationStyle: String, CaseIterable, Identifiable {
    case apa7 = "apa7"           // APA 第七版
    case apa6 = "apa6"           // APA 第六版
    case chicago = "chicago"     // Chicago
    case mla = "mla"             // MLA
    case ieee = "ieee"           // IEEE
    case harvard = "harvard"     // Harvard
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .apa7: return "APA 第七版"
        case .apa6: return "APA 第六版"
        case .chicago: return "Chicago"
        case .mla: return "MLA"
        case .ieee: return "IEEE"
        case .harvard: return "Harvard"
        }
    }
    
    var promptDescription: String {
        switch self {
        case .apa7:
            return "APA 第七版格式（作者-年份制）"
        case .apa6:
            return "APA 第六版格式"
        case .chicago:
            return "Chicago 格式（作者-日期制或註腳制）"
        case .mla:
            return "MLA 格式（作者-頁碼制）"
        case .ieee:
            return "IEEE 格式（數字編號制）"
        case .harvard:
            return "Harvard 格式（作者-年份制）"
        }
    }
}

// MARK: - 引用問題

/// 引用問題
public struct CitationIssue: Identifiable {
    public let id = UUID()
    public let original: String
    public let description: String
    public let suggestion: String?
    public let severity: Severity
    public let reference: String?
    
    public enum Severity: String {
        case error = "error"
        case warning = "warning"
        case suggestion = "suggestion"
    }
}

// MARK: - 引用 AI 領域

/// 引用 AI 領域
@available(macOS 26.0, *)
@MainActor
public class CitationAIDomain {
    
    private weak var service: UnifiedAIService?
    
    init(service: UnifiedAIService) {
        self.service = service
    }
    
    // MARK: - 檢查引用格式
    
    /// 檢查引用格式
    /// - Parameters:
    ///   - text: 包含引用的文字
    ///   - style: 引用格式樣式
    /// - Returns: 引用問題列表
    public func checkFormat(text: String, style: CitationStyle = .apa7) async throws -> [CitationIssue] {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !text.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        let truncatedText = String(text.prefix(4000))
        
        let prompt = """
        你是台灣學術引用格式專家。請檢查以下文本的引用格式是否符合 \(style.displayName) 規範。
        
        文本：
        ---
        \(truncatedText)
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
        
        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        [
          {
            "original": "原始引用文字",
            "description": "問題描述",
            "suggestion": "正確格式",
            "severity": "warning",
            "reference": "\(style.displayName) 引用規範"
          }
        ]
        
        severity 可選值：error, warning, suggestion
        如果沒有發現問題，回覆空陣列 []
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseCitationIssuesResponse(response.content)
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.citationFormatError(error.localizedDescription)
        }
    }
    
    // MARK: - 修正引用格式
    
    /// 修正引用格式
    /// - Parameters:
    ///   - text: 包含引用的文字
    ///   - style: 目標引用格式
    /// - Returns: 修正後的文字
    public func fixFormat(text: NSAttributedString, style: CitationStyle = .apa7) async throws -> NSAttributedString {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        
        let plainText = text.string
        guard !plainText.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        let prompt = """
        請將以下文字中的引用格式修正為 \(style.promptDescription)。
        
        **\(style.displayName) 文內引用規則：**
        - 單一作者：(王小明, 2024) 或 (Smith, 2024)
        - 兩位作者：(王小明、李大華, 2024) 或 (Smith & Jones, 2024)
        - 三位以上作者：(王小明等人, 2024) 或 (Smith et al., 2024)
        - 直接引用加頁碼：(Smith, 2024, p. 25)
        
        原文：
        ---
        \(plainText)
        ---
        
        請直接回傳修正後的完整文字，不要額外說明。保持原文結構，只修正引用格式。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            let correctedText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return NSAttributedString(string: correctedText)
        } catch {
            throw AIServiceError.citationFormatError(error.localizedDescription)
        }
    }
    
    // MARK: - 轉換引用格式
    
    /// 轉換引用格式
    /// - Parameters:
    ///   - citation: 引用文字
    ///   - from: 原始格式
    ///   - to: 目標格式
    /// - Returns: 轉換後的引用
    public func convert(citation: String, from: CitationStyle, to: CitationStyle) async throws -> String {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !citation.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        if from == to {
            return citation
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        let prompt = """
        請將以下引用從 \(from.displayName) 格式轉換為 \(to.displayName) 格式。
        
        原始引用：
        \(citation)
        
        只回覆轉換後的引用，不要其他說明。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw AIServiceError.citationFormatError(error.localizedDescription)
        }
    }
    
    // MARK: - 生成引用
    
    /// 根據元數據生成引用
    /// - Parameters:
    ///   - title: 標題
    ///   - authors: 作者列表
    ///   - year: 年份
    ///   - journal: 期刊名稱
    ///   - volume: 卷號
    ///   - issue: 期號
    ///   - pages: 頁碼
    ///   - doi: DOI
    ///   - style: 引用格式
    /// - Returns: 生成的引用
    public func generate(
        title: String,
        authors: [String],
        year: String?,
        journal: String? = nil,
        volume: String? = nil,
        issue: String? = nil,
        pages: String? = nil,
        doi: String? = nil,
        style: CitationStyle = .apa7
    ) async throws -> String {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        var metadataInfo = """
        標題：\(title)
        作者：\(authors.joined(separator: ", "))
        """
        
        if let year = year { metadataInfo += "\n年份：\(year)" }
        if let journal = journal { metadataInfo += "\n期刊：\(journal)" }
        if let volume = volume { metadataInfo += "\n卷號：\(volume)" }
        if let issue = issue { metadataInfo += "\n期號：\(issue)" }
        if let pages = pages { metadataInfo += "\n頁碼：\(pages)" }
        if let doi = doi { metadataInfo += "\nDOI：\(doi)" }
        
        let prompt = """
        請根據以下書目資訊生成 \(style.displayName) 格式的參考文獻引用。
        
        \(metadataInfo)
        
        只回覆格式化的引用，不要其他說明。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw AIServiceError.citationFormatError(error.localizedDescription)
        }
    }
    
    // MARK: - 私有方法
    
    private func parseCitationIssuesResponse(_ response: String) throws -> [CitationIssue] {
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
            return []
        }
        
        return jsonArray.compactMap { dict -> CitationIssue? in
            guard let original = dict["original"] as? String,
                  let description = dict["description"] as? String else { return nil }
            
            let severityStr = dict["severity"] as? String ?? "warning"
            let severity: CitationIssue.Severity
            switch severityStr {
            case "error": severity = .error
            case "suggestion": severity = .suggestion
            default: severity = .warning
            }
            
            return CitationIssue(
                original: original,
                description: description,
                suggestion: dict["suggestion"] as? String,
                severity: severity,
                reference: dict["reference"] as? String
            )
        }
    }
}
