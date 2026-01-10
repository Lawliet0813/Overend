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
    
    /// 計算提取的信心度
    public var confidence: PDFMetadataConfidence {
        var score = 0
        
        // DOI = 最高分（有 DOI 就能查到完整書目）
        if doi != nil { score += 40 }
        
        // 標題 = 必要（至少要 10 個字才算有效標題）
        if let titleText = title, titleText.count > 10 {
            score += 20
        }
        
        // 作者 = 重要
        if !authors.isEmpty { score += 20 }
        
        // 年份 = 重要
        if year != nil { score += 10 }
        
        // 期刊 = 加分
        if journal != nil { score += 10 }
        
        // 根據分數判斷信心度
        if score >= 70 {
            return .high
        } else if score >= 40 {
            return .medium
        } else {
            return .low
        }
    }
}

/// PDF 元數據信心度
public enum PDFMetadataConfidence {
    case high    // 高可信度（DOI 查詢或完整資訊）
    case medium  // 中等可信度（AI 提取到大部分資訊）
    case low     // 低可信度（僅部分資訊）
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
    
    /// 生成文獻摘要（使用 Tool Calling）
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
        
        var inputText = "標題：\(title)"
        if let abstract = abstract, !abstract.isEmpty {
            inputText += "\n原始摘要：\(abstract)"
        }
        if let content = content, !content.isEmpty {
            inputText += "\n內容節錄：\(String(content.prefix(2000)))"
        }
        
        // 策略 1: Tool Calling
        do {
            let tool = GenerateSummaryTool()
            let session = GenerateSummaryTool.createSession(with: tool)
            
            let prompt = """
            請為以下學術文獻生成摘要：
            
            \(inputText)
            """
            
            let _ = try await session.respond(to: prompt)
            
            if let result = tool.result {
                print("✅ Tool Calling 摘要生成成功")
                return result.summary
            }
        } catch {
            print("⚠️ Tool Calling 失敗: \(error.localizedDescription)，降級到 Prompt 方式")
        }
        
        // 策略 2: Prompt 方式降級
        let session = service.acquireSession()
        defer { service.releaseSession(session) }
        
        let prompt = """
        請為以下學術文獻生成一段簡潔的中文摘要（約 100-150 字）：
        
        \(inputText)
        
        請用繁體中文回覆，保持學術風格。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw AIServiceError.summaryGenerationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 提取關鍵詞
    
    /// 從文獻中提取關鍵詞（使用 Tool Calling）
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
        
        let inputText = "標題：\(title)\n摘要：\(abstract)"
        
        // 策略 1: Tool Calling
        do {
            let tool = ExtractKeywordsTool()
            let session = ExtractKeywordsTool.createSession(with: tool)
            
            let prompt = """
            請從以下文獻中提取關鍵詞：
            
            \(inputText)
            """
            
            let _ = try await session.respond(to: prompt)
            
            if let result = tool.result, !result.keywords.isEmpty {
                print("✅ Tool Calling 關鍵詞提取成功")
                return result.keywords
            }
        } catch {
            print("⚠️ Tool Calling 失敗: \(error.localizedDescription)，降級到 Prompt 方式")
        }
        
        // 策略 2: Prompt 方式降級
        let session = service.acquireSession()
        defer { service.releaseSession(session) }
        
        let prompt = """
        請從以下學術文獻中提取 5-8 個關鍵詞，用逗號分隔：
        
        \(inputText)
        
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
        
        let session = service.acquireSession()
        defer { service.releaseSession(session) }
        
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
    
    /// 從 PDF 文字中提取元數據（使用 Tool Calling）
    /// - Parameter pdfText: PDF 提取的文字
    /// - Returns: 識別出的元數據
    public func extractMetadata(from pdfText: String) async throws -> ExtractedDocumentMetadata {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let cleanedText = sanitizePDFText(pdfText)
        let truncatedText = String(cleanedText.prefix(4000))
        
        // ========================================
        // 策略 1️⃣: Tool Calling（優先）
        // ========================================
        do {
            let result = try await extractMetadataWithToolCalling(text: truncatedText)
            if result.hasData {
                print("✅ Tool Calling 提取成功")
                return augmentMetadata(result, with: truncatedText)
            }
            print("⚠️ Tool Calling 結果不完整，降級到 Prompt 方式")
        } catch {
            print("⚠️ Tool Calling 失敗: \(error.localizedDescription)，降級到 Prompt 方式")
        }
        
        // ========================================
        // 策略 2️⃣: Prompt 方式（降級）
        // ========================================
        return try await extractMetadataWithPrompt(text: truncatedText)
    }
    
    // MARK: - Tool Calling 提取
    
    /// 使用 Tool Calling 提取元數據
    private func extractMetadataWithToolCalling(text: String) async throws -> ExtractedDocumentMetadata {
        let tool = ExtractPDFMetadataTool()
        let session = ExtractPDFMetadataTool.createSession(with: tool)
        
        let prompt = """
        分析以下學術文獻的內容，提取書目資訊後調用 extractPDFMetadata 工具：
        
        ---
        \(text)
        ---
        """
        
        let response = try await session.respond(to: prompt)
        
        // 檢查工具是否被調用並取得結果
        if let result = tool.extractedResult {
            return result
        }
        
        // 如果工具沒有被調用，嘗試解析回應內容
        throw AIServiceError.processingFailed("Tool was not called by the model")
    }
    
    // MARK: - Prompt 方式提取（降級）
    
    /// 使用傳統 Prompt + JSON 解析方式提取元數據
    private func extractMetadataWithPrompt(text: String) async throws -> ExtractedDocumentMetadata {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        let session = service.acquireSession()
        defer { service.releaseSession(session) }
        
        let preDetectedDOI = detectDOI(in: text)
        let preDetectedYear = detectYear(in: text)
        let preDetectedTitle = detectTitle(in: text)

        var detectedInfo = ""
        if let d = preDetectedDOI { detectedInfo += "\n偵測到 DOI：\(d)" }
        if let y = preDetectedYear { detectedInfo += "\n偵測到年份：\(y)" }
        if let t = preDetectedTitle { detectedInfo += "\n偵測到可能標題：\(t)" }
        
        let prompt = """
        請分析以下學術文獻 PDF 的文字內容，提取書目資訊，並以『純 JSON』回覆（不要任何解釋、不要包含 ``` 區塊）。

        文獻內容（已截斷）：
        ---
        \(text)
        ---

        附加線索（若與內容矛盾，以內容為準）：
        \(detectedInfo.isEmpty ? "(無)" : detectedInfo)

        請回覆以下 JSON（鍵名固定，值允許為 null）：
        {
          "title": null,          // 完整標題字串
          "authors": [],          // 作者陣列（每位作者為字串；中文保留原順序；英文建議 "Last, F."）
          "year": null,           // 四位數年份（如 2024）
          "journal": null,        // 期刊或出版社
          "doi": null,            // DOI（標準格式，不含 URL 前綴）
          "type": "article"      // article/book/inproceedings/thesis/misc
        }

        嚴格要求：
        1. 只回覆上述 JSON 物件。
        2. authors 必須是字串陣列；若無法確定，回傳空陣列。
        3. year 必須為四位數字；無法確定則為 null。
        4. doi 請輸出標準 DOI（例如：10.1145/3368089.3409690），不要包含 https://doi.org/ 或 doi: 前綴。
        5. type 僅能為 article/book/inproceedings/thesis/misc。
        6. 請使用繁體中文語境判斷（若可）。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            var metadata = try parseMetadataResponse(response.content)
            metadata = augmentMetadata(metadata, with: text)

            if !metadata.hasData {
                // Retry once with a stricter prompt and shorter context
                let retryPrompt = """
                嚴格只回覆 JSON，不要任何解釋、不要 ``` 區塊。請根據以下內容提取：
                ---
                \(String(text.prefix(2000)))
                ---
                JSON 模板：
                {
                  "title": null,
                  "authors": [],
                  "year": null,
                  "journal": null,
                  "doi": null,
                  "type": "article"
                }

                規則：authors 為字串陣列；year 為四位數；doi 為標準 DOI；type 僅能為 article/book/inproceedings/thesis/misc。
                """
                let retryResponse = try await session.respond(to: retryPrompt)
                var retryMetadata = try parseMetadataResponse(retryResponse.content)
                retryMetadata = augmentMetadata(retryMetadata, with: text)
                return retryMetadata
            }

            return metadata
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
        
        let session = service.acquireSession()
        defer { service.releaseSession(session) }
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
            // ❗ 佔位符檢測
            if !isPlaceholderTitle(title) {
                metadata.title = title
            } else {
                print("⚠️ Prompt 提取偵測到佔位符標題: \(title)，已過濾")
            }
        }
        
        if let authorsArray = json["authors"] as? [String] {
            // ❗ 過濾佔位符作者
            let filteredAuthors = authorsArray
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0.lowercased() != "null" && !isPlaceholderAuthor($0) }
            metadata.authors = filteredAuthors
            
            if filteredAuthors.count < authorsArray.count {
                print("⚠️ Prompt 提取過濾掉 \(authorsArray.count - filteredAuthors.count) 個佔位符作者")
            }
        } else if let authorsStr = json["authors"] as? String {
            let parts = authorsStr
                .replacingOccurrences(of: ";", with: ",")
                .components(separatedBy: CharacterSet(charactersIn: "，,、| and "))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !isPlaceholderAuthor($0) }
            metadata.authors = parts
        }
        
        if let yearStr = json["year"] as? String {
            let trimmed = yearStr.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count == 4, Int(trimmed) != nil {
                metadata.year = trimmed
            } else if let y = extractFourDigitYear(from: trimmed) {
                metadata.year = y
            }
        } else if let yearInt = json["year"] as? Int {
            metadata.year = String(yearInt)
        }
        
        if let journal = json["journal"] as? String, !journal.isEmpty, journal.lowercased() != "null" {
            // ❗ 檢測期刊佔位符
            if !isPlaceholderJournal(journal) {
                metadata.journal = journal
            }
        }
        
        if let doi = json["doi"] as? String, !doi.isEmpty, doi.lowercased() != "null" {
            metadata.doi = normalizeDOI(doi)
        }
        
        if let type = json["type"] as? String {
            metadata.entryType = type.lowercased()
        }
        
        return metadata
    }
    
    // MARK: - 佔位符檢測
    
    /// 已知的標題佔位符
    private let titlePlaceholders: Set<String> = [
        "論文標題", "文章標題", "書籍標題", "標題", "未知標題", "無標題",
        "Title", "Article Title", "Paper Title", "Book Title", "Unknown Title",
        "測試標題", "範例標題", "Example Title", "Sample Title"
    ]
    
    /// 已知的作者佔位符
    private let authorPlaceholders: Set<String> = [
        "作者1", "作者2", "作者3", "作者", "未知作者",
        "Author 1", "Author 2", "Author 3", "Author", "Unknown Author",
        "張三", "李四", "王五", "某某人", "佚名",
        "John Doe", "Jane Doe", "First Author", "Second Author"
    ]
    
    /// 已知的期刊佔位符
    private let journalPlaceholders: Set<String> = [
        "期刊名稱", "會議名稱", "出版社", "未知期刊",
        "Journal Name", "Conference Name", "Publisher", "Unknown Journal"
    ]
    
    /// 檢查標題是否為佔位符
    private func isPlaceholderTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if titlePlaceholders.contains(trimmed) {
            return true
        }
        
        // 檢查是否過短
        if trimmed.count < 5 {
            return true
        }
        
        // 檢查是否包含佔位符關鍵詞
        let lowerTitle = trimmed.lowercased()
        let keywords = ["論文標題", "文章標題", "書籍標題", "paper title", "article title"]
        for keyword in keywords {
            if lowerTitle.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    /// 檢查作者是否為佔位符
    private func isPlaceholderAuthor(_ author: String) -> Bool {
        let trimmed = author.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if authorPlaceholders.contains(trimmed) {
            return true
        }
        
        // 檢查「作者+數字」模式
        let pattern = #"^(作者|Author|author)\s*\d*$"#
        if trimmed.range(of: pattern, options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    /// 檢查期刊是否為佔位符
    private func isPlaceholderJournal(_ journal: String) -> Bool {
        let trimmed = journal.trimmingCharacters(in: .whitespacesAndNewlines)
        return journalPlaceholders.contains(trimmed)
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
    
    private func sanitizePDFText(_ text: String) -> String {
        var t = text
        // Join hyphenated line breaks (e.g., "exam-\nple" -> "example")
        t = t.replacingOccurrences(of: "-\n", with: "")
        // Normalize newlines and spaces
        t = t.replacingOccurrences(of: "\r", with: "\n")
        t = t.replacingOccurrences(of: "\n{2,}", with: "\n", options: .regularExpression)
        t = t.replacingOccurrences(of: "[\t\u{00A0}]", with: " ", options: .regularExpression)
        t = t.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)

        // Remove reference section to reduce noise
        let cutMarkers = ["\nReferences\n", "\nREFERENCE\n", "\n參考文獻\n", "\n參考資料\n"]
        for marker in cutMarkers {
            if let range = t.range(of: marker, options: [.caseInsensitive]) {
                let prefix = String(t[..<range.lowerBound])
                if prefix.count > 500 { // keep at least some content
                    t = prefix
                }
                break
            }
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func detectDOI(in text: String) -> String? {
        // DOI regex per CrossRef recommendation (simplified)
        let pattern = #"10\.\d{4,9}/[-._;()/:A-Z0-9]+"#
        if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
            let raw = String(text[range])
            return normalizeDOI(raw)
        }
        // Also handle URL form
        if let range = text.range(of: #"https?://doi\.org/([A-Z0-9./_-]+)"#, options: [.regularExpression, .caseInsensitive]) {
            let raw = String(text[range])
            return normalizeDOI(raw)
        }
        return nil
    }
    
    private func normalizeDOI(_ doi: String) -> String {
        var d = doi.trimmingCharacters(in: .whitespacesAndNewlines)
        d = d.replacingOccurrences(of: "https://doi.org/", with: "", options: .caseInsensitive)
        d = d.replacingOccurrences(of: "http://doi.org/", with: "", options: .caseInsensitive)
        d = d.replacingOccurrences(of: "doi:", with: "", options: .caseInsensitive)
        d = d.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        return d
    }
    
    private func detectYear(in text: String) -> String? {
        let pattern = #"\b(19\d{2}|20\d{2})\b"#
        if let range = text.range(of: pattern, options: [.regularExpression]) {
            return String(text[range])
        }
        return nil
    }
    
    private func extractFourDigitYear(from text: String) -> String? {
        let pattern = #"\b(19\d{2}|20\d{2})\b"#
        if let range = text.range(of: pattern, options: [.regularExpression]) {
            return String(text[range])
        }
        return nil
    }
    
    private func detectTitle(in text: String) -> String? {
        // Heuristic: pick the first reasonably long line near the beginning that doesn't look like section headings
        let lines = text.components(separatedBy: .newlines).prefix(30)
        let banned = ["abstract", "introduction", "目錄", "摘要", "參考文獻", "references", "contents"]
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 10 && trimmed.count < 200 {
                let lower = trimmed.lowercased()
                if !banned.contains(where: { lower.contains($0) }) {
                    return trimmed
                }
            }
        }
        return nil
    }
    
    private func augmentMetadata(_ metadata: ExtractedDocumentMetadata, with context: String) -> ExtractedDocumentMetadata {
        var m = metadata
        if m.doi == nil, let d = detectDOI(in: context) { m.doi = d }
        if m.year == nil, let y = detectYear(in: context) { m.year = y }
        if (m.title == nil || (m.title?.count ?? 0) <= 10), let t = detectTitle(in: context) { m.title = t }
        return m
    }
}

