//
//  DocumentAIDomain.swift
//  OVEREND
//
//  文件處理 AI 領域 - 整合所有文件處理相關的 AI 功能
//
//  整合來源：
//  - AppleAIService (摘要、關鍵詞、分類、元數據)
//  - AILayoutFormatter (排版)
//

import Foundation
import AppKit
import FoundationModels

// MARK: - 排版類型

/// 排版類型
public enum FormattingType: String, CaseIterable {
    case academic = "academic"       // 學術論文排版
    case report = "report"           // 報告排版
    case thesis = "thesis"           // 學位論文排版
    case article = "article"         // 期刊文章排版
    
    public var displayName: String {
        switch self {
        case .academic: return "學術論文"
        case .report: return "報告"
        case .thesis: return "學位論文"
        case .article: return "期刊文章"
        }
    }
}

/// 排版結果
public struct FormattingResult {
    public let formattedText: NSAttributedString
    public let changes: [String]
    public let suggestions: [String]
}

// MARK: - 元數據

/// 提取的元數據
public struct ExtractedDocumentMetadata {
    public var title: String?
    public var authors: [String] = []
    public var year: String?
    public var journal: String?
    public var doi: String?
    public var entryType: String?
    
    public var hasData: Bool {
        title != nil || !authors.isEmpty || year != nil || journal != nil || doi != nil
    }
    
    public var authorsBibTeX: String {
        authors.joined(separator: " and ")
    }
}

// MARK: - 文件處理 AI 領域

/// 文件處理 AI 領域
@available(macOS 26.0, *)
@MainActor
public class DocumentAIDomain {
    
    private weak var service: UnifiedAIService?
    
    init(service: UnifiedAIService) {
        self.service = service
    }
    
    // MARK: - 生成摘要
    
    /// 生成文獻摘要
    /// - Parameters:
    ///   - title: 標題
    ///   - abstract: 原始摘要
    ///   - content: 內容
    /// - Returns: 生成的摘要
    public func generateSummary(
        title: String,
        abstract: String? = nil,
        content: String? = nil
    ) async throws -> String {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        var prompt = """
        請為以下學術文獻生成一段簡潔的中文摘要（約 100-150 字）：
        
        標題：\(title)
        """
        
        if let abstract = abstract, !abstract.isEmpty {
            prompt += "\n原始摘要：\(abstract)"
        }
        
        if let content = content, !content.isEmpty {
            let truncatedContent = String(content.prefix(2000))
            prompt += "\n內容節錄：\(truncatedContent)"
        }
        
        prompt += "\n\n請用繁體中文回覆，保持學術風格。"
        
        do {
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw AIServiceError.summaryGenerationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 提取關鍵詞
    
    /// 從文獻中提取關鍵詞
    /// - Parameters:
    ///   - title: 標題
    ///   - abstract: 摘要
    /// - Returns: 關鍵詞列表
    public func extractKeywords(title: String, abstract: String) async throws -> [String] {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        let prompt = """
        請從以下學術文獻中提取 5-8 個關鍵詞，用逗號分隔：
        
        標題：\(title)
        摘要：\(abstract)
        
        只回覆關鍵詞，用逗號分隔，不要其他文字。使用繁體中文。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            let keywords = response.content
                .components(separatedBy: CharacterSet(charactersIn: "，,、"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return keywords
        } catch {
            throw AIServiceError.processingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 智慧分類
    
    /// 推薦文獻分類
    /// - Parameters:
    ///   - title: 標題
    ///   - abstract: 摘要
    ///   - existingGroups: 現有分組
    /// - Returns: 建議的分類
    public func suggestCategories(
        title: String,
        abstract: String,
        existingGroups: [String]
    ) async throws -> [String] {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        let groupList = existingGroups.isEmpty
            ? "（目前沒有現有分組）"
            : existingGroups.joined(separator: "、")
        
        let prompt = """
        根據以下文獻資訊，建議適合的分類：
        
        標題：\(title)
        摘要：\(abstract)
        
        現有分組：\(groupList)
        
        請建議 1-3 個最適合的分組名稱，優先使用現有分組。
        如果需要新分組，請建議簡潔的中文名稱。
        只回覆分組名稱，用逗號分隔。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            let categories = response.content
                .components(separatedBy: CharacterSet(charactersIn: "，,、"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return categories
        } catch {
            throw AIServiceError.processingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 提取 PDF 元數據
    
    /// 從 PDF 文字中提取元數據
    /// - Parameter pdfText: PDF 提取的文字
    /// - Returns: 識別出的元數據
    public func extractMetadata(from pdfText: String) async throws -> ExtractedDocumentMetadata {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        let truncatedText = String(pdfText.prefix(3000))
        
        let prompt = """
        請分析以下學術文獻 PDF 的文字內容，提取書目資訊。

        文獻內容：
        ---
        \(truncatedText)
        ---

        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        {
          "title": null,
          "authors": [],
          "year": null,
          "journal": null,
          "doi": null,
          "type": "article"
        }

        欄位說明：
        1. title: 從 PDF 提取的完整標題
        2. authors: 作者姓名陣列
        3. year: 出版年份（四位數字）
        4. journal: 期刊或出版社名稱
        5. doi: DOI（如有）
        6. type: article/book/inproceedings/thesis/misc

        只回覆 JSON，不要其他文字。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseMetadataResponse(response.content)
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.metadataExtractionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 智慧排版
    
    /// 智慧排版
    /// - Parameters:
    ///   - text: 原始文字
    ///   - type: 排版類型
    /// - Returns: 排版結果
    public func format(
        text: NSAttributedString,
        type: FormattingType
    ) async throws -> FormattingResult {
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
        let truncatedText = String(plainText.prefix(3000))
        
        let prompt = buildFormattingPrompt(for: type, with: truncatedText)
        
        do {
            let response = try await session.respond(to: prompt)
            let responseText = response.content
            
            // 簡化處理：返回原文和建議
            return FormattingResult(
                formattedText: text,
                changes: extractChanges(from: responseText),
                suggestions: extractSuggestions(from: responseText)
            )
        } catch {
            throw AIServiceError.processingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 私有方法
    
    private func parseMetadataResponse(_ response: String) throws -> ExtractedDocumentMetadata {
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let jsonStart = cleanedResponse.firstIndex(of: "{"),
           let jsonEnd = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        guard let data = cleanedResponse.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ExtractedDocumentMetadata()
        }
        
        var metadata = ExtractedDocumentMetadata()
        
        if let title = json["title"] as? String, !title.isEmpty, title.lowercased() != "null" {
            metadata.title = title
        }
        
        if let authors = json["authors"] as? [String] {
            metadata.authors = authors.filter { !$0.isEmpty && $0.lowercased() != "null" }
        }
        
        if let year = json["year"] as? String, year.count == 4 {
            metadata.year = year
        } else if let yearInt = json["year"] as? Int {
            metadata.year = String(yearInt)
        }
        
        if let journal = json["journal"] as? String, !journal.isEmpty, journal.lowercased() != "null" {
            metadata.journal = journal
        }
        
        if let doi = json["doi"] as? String, !doi.isEmpty, doi.lowercased() != "null" {
            metadata.doi = doi
        }
        
        if let type = json["type"] as? String {
            metadata.entryType = type.lowercased()
        }
        
        return metadata
    }
    
    private func buildFormattingPrompt(for type: FormattingType, with text: String) -> String {
        switch type {
        case .academic:
            return """
            請以 APA 第 7 版學術論文格式審閱以下文字，提供格式建議：
            
            \(text)
            
            請提供：
            1. 格式改進建議
            2. 標題層級建議
            3. 引用格式建議
            """
            
        case .thesis:
            return """
            請以台灣碩博士論文格式審閱以下文字，提供格式建議：
            
            \(text)
            
            請提供：
            1. 章節編號建議
            2. 格式調整建議
            3. 參考文獻格式建議
            """
            
        case .report:
            return """
            請以正式報告格式審閱以下文字，提供格式建議：
            
            \(text)
            
            請提供格式化建議。
            """
            
        case .article:
            return """
            請以期刊文章格式審閱以下文字，提供格式建議：
            
            \(text)
            
            請提供格式化建議。
            """
        }
    }
    
    private func extractChanges(from response: String) -> [String] {
        // 簡化實作：從回應中提取改動說明
        let lines = response.components(separatedBy: .newlines)
        return lines.filter { $0.contains("修改") || $0.contains("調整") || $0.contains("改為") }
    }
    
    private func extractSuggestions(from response: String) -> [String] {
        // 簡化實作：從回應中提取建議
        let lines = response.components(separatedBy: .newlines)
        return lines.filter { $0.contains("建議") || $0.contains("可以") || $0.contains("應該") }
    }
}
