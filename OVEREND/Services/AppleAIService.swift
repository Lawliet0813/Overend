//
//  AppleAIService.swift
//  OVEREND
//
//  Apple Foundation Models 整合 - 設備端 AI 功能
//
//  支援功能：
//  - 文獻摘要生成
//  - 關鍵詞提取
//  - 寫作建議
//  - 智慧分類
//

import Foundation
import SwiftUI
import Combine
import FoundationModels

/// Apple AI 服務 - 使用 Foundation Models 框架
@available(macOS 26.0, *)
@MainActor
class AppleAIService: ObservableObject {
    
    static let shared = AppleAIService()
    
    // MARK: - 狀態
    @Published var isAvailable: Bool = false
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    private init() {
        checkAvailability()
    }
    
    // MARK: - 可用性檢查
    
    /// 檢查 Apple Intelligence 是否可用
    func checkAvailability() {
        Task {
            do {
                // 嘗試建立 session 來檢查可用性
                _ = LanguageModelSession()
                // 如果能成功建立，表示可用
                isAvailable = true
                print("✅ Apple Intelligence 可用")
            } catch {
                isAvailable = false
                errorMessage = "Apple Intelligence 不可用：\(error.localizedDescription)"
                print("❌ Apple Intelligence 不可用：\(error)")
            }
        }
    }
    
    // MARK: - 文獻摘要生成
    
    /// 生成文獻摘要
    func generateSummary(title: String, abstract: String? = nil, content: String? = nil) async throws -> String {
        guard isAvailable else {
            throw AIError.notAvailable
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let session = LanguageModelSession()
        
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
            return response.content
        } catch {
            throw AIError.generationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 關鍵詞提取
    
    /// 從文獻中提取關鍵詞
    func extractKeywords(title: String, abstract: String) async throws -> [String] {
        guard isAvailable else {
            throw AIError.notAvailable
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let session = LanguageModelSession()
        
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
            throw AIError.generationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 寫作建議
    
    /// 為寫作內容提供改進建議
    func getWritingSuggestions(for text: String) async throws -> String {
        guard isAvailable else {
            throw AIError.notAvailable
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let session = LanguageModelSession()
        let truncatedText = String(text.prefix(1500))
        
        let prompt = """
        請審閱以下學術寫作片段，並提供改進建議：
        
        ---
        \(truncatedText)
        ---
        
        請提供：
        1. 語法和標點符號修正建議
        2. 學術表達優化建議
        3. 邏輯連貫性建議
        
        使用繁體中文回覆，簡潔明瞭。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            throw AIError.generationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 智慧分類
    
    /// 推薦文獻分類
    func suggestCategories(
        title: String,
        abstract: String,
        existingGroups: [String]
    ) async throws -> [String] {
        guard isAvailable else {
            throw AIError.notAvailable
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let session = LanguageModelSession()
        
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
            throw AIError.generationFailed(error.localizedDescription)
        }
    }
    
    /// 從 PDF 提取的文字中識別文獻元數據
    /// - Parameter text: PDF 提取的文字內容（通常是前幾頁）
    /// - Returns: 識別出的元數據
    func extractMetadata(from text: String) async throws -> ExtractedMetadata {
        guard isAvailable else {
            throw AIError.notAvailable
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let session = LanguageModelSession()
        
        // 截取適當長度的文字（前 3000 字元通常包含標題和作者）
        let truncatedText = String(text.prefix(3000))
        
        let prompt = """
        請分析以下學術文獻 PDF 的文字內容，提取書目資訊。

        文獻內容：
        ---
        \(truncatedText)
        ---

        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        {
          "title": "完整標題",
          "authors": ["作者1", "作者2", "作者3"],
          "year": "YYYY",
          "journal": "期刊或會議名稱",
          "doi": "10.xxxx/xxxxx",
          "type": "article"
        }

        重要提示：
        - 標題：通常在第一頁頂部，字體較大，是完整的論文標題
        - 作者：通常在標題下方，是作者姓名列表
        - 年份：4位數字，範圍 1990-2025
        - 期刊：期刊、會議或出版社名稱
        - DOI：格式為 10.xxxx/xxxxx，如果有的話
        - type：必須是以下之一
          * article - 期刊論文
          * book - 書籍
          * inproceedings - 會議論文
          * thesis - 碩博士論文
          * techreport - 技術報告
          * misc - 其他
        - 如果找不到某欄位，請設為 null（不要用字串 "null"）

        只回覆 JSON 格式，不要其他說明文字。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return parseMetadataResponse(response.content)
        } catch {
            throw AIError.generationFailed(error.localizedDescription)
        }
    }
    
    /// 解析 AI 回應的元數據（優先使用 JSON 格式）
    private func parseMetadataResponse(_ response: String) -> ExtractedMetadata {
        var metadata = ExtractedMetadata()
        
        // 先嘗試解析 JSON 格式
        if let jsonMetadata = parseJSONFormat(response) {
            print("✅ 成功解析 JSON 格式")
            return jsonMetadata
        }
        
        // 降級：嘗試解析舊的文字格式
        print("⚠️ JSON 解析失敗，嘗試文字格式")
        return parseTextFormat(response)
    }
    
    /// 解析 JSON 格式的回應
    private func parseJSONFormat(_ response: String) -> ExtractedMetadata? {
        // 清理回應（移除可能的 markdown 程式碼區塊）
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 嘗試提取 JSON 區塊（處理 AI 可能在前後加說明文字的情況）
        if let jsonStart = cleanedResponse.firstIndex(of: "{"),
           let jsonEnd = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        // 嘗試解析 JSON
        guard let data = cleanedResponse.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        var metadata = ExtractedMetadata()
        
        // 提取標題
        if let title = json["title"] as? String, 
           !title.isEmpty, 
           title.lowercased() != "null" {
            metadata.title = title
        }
        
        // 提取作者
        if let authors = json["authors"] as? [String] {
            metadata.authors = authors.filter { !$0.isEmpty && $0.lowercased() != "null" }
        } else if let authorsString = json["authors"] as? String {
            // 處理 AI 返回字串而非陣列的情況
            metadata.authors = authorsString
                .components(separatedBy: CharacterSet(charactersIn: ";,，"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.lowercased() != "null" }
        }
        
        // 提取年份
        if let year = json["year"] as? String, year.count == 4 {
            metadata.year = year
        } else if let yearInt = json["year"] as? Int {
            metadata.year = String(yearInt)
        }
        
        // 提取期刊
        if let journal = json["journal"] as? String, 
           !journal.isEmpty, 
           journal.lowercased() != "null" {
            metadata.journal = journal
        }
        
        // 提取 DOI
        if let doi = json["doi"] as? String, 
           !doi.isEmpty, 
           doi.lowercased() != "null" {
            metadata.doi = doi
        }
        
        // 提取類型
        if let type = json["type"] as? String {
            let validTypes = ["article", "book", "inproceedings", "thesis", "techreport", "misc"]
            metadata.entryType = validTypes.contains(type.lowercased()) ? type.lowercased() : "misc"
        }
        
        return metadata
    }
    
    /// 解析文字格式的回應（降級方案）
    private func parseTextFormat(_ response: String) -> ExtractedMetadata {
        var metadata = ExtractedMetadata()
        
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.hasPrefix("標題:") || trimmedLine.hasPrefix("標題：") {
                let value = extractValue(from: trimmedLine)
                if value != "未知" && !value.isEmpty {
                    metadata.title = value
                }
            } else if trimmedLine.hasPrefix("作者:") || trimmedLine.hasPrefix("作者：") {
                let value = extractValue(from: trimmedLine)
                if value != "未知" && !value.isEmpty {
                    metadata.authors = value
                        .components(separatedBy: CharacterSet(charactersIn: ";；,，"))
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                }
            } else if trimmedLine.hasPrefix("年份:") || trimmedLine.hasPrefix("年份：") {
                let value = extractValue(from: trimmedLine)
                if value != "未知" && !value.isEmpty {
                    // 提取 4 位數字年份
                    let yearPattern = "\\d{4}"
                    if let range = value.range(of: yearPattern, options: .regularExpression) {
                        metadata.year = String(value[range])
                    }
                }
            } else if trimmedLine.hasPrefix("期刊:") || trimmedLine.hasPrefix("期刊：") {
                let value = extractValue(from: trimmedLine)
                if value != "未知" && !value.isEmpty {
                    metadata.journal = value
                }
            } else if trimmedLine.hasPrefix("DOI:") || trimmedLine.hasPrefix("DOI：") {
                let value = extractValue(from: trimmedLine)
                if value != "未知" && !value.isEmpty {
                    metadata.doi = value
                }
            } else if trimmedLine.hasPrefix("類型:") || trimmedLine.hasPrefix("類型：") {
                let value = extractValue(from: trimmedLine).lowercased()
                if value != "未知" && !value.isEmpty {
                    // 驗證是否為有效的文獻類型
                    let validTypes = ["article", "book", "inproceedings", "thesis", "techreport", "misc"]
                    if validTypes.contains(value) {
                        metadata.entryType = value
                    } else {
                        metadata.entryType = "misc"
                    }
                }
            }
        }
        
        return metadata
    }
    
    /// 從「標籤: 值」格式中提取值
    private func extractValue(from line: String) -> String {
        if let colonIndex = line.firstIndex(of: ":") ?? line.firstIndex(of: "：") {
            let valueStart = line.index(after: colonIndex)
            return String(line[valueStart...]).trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
}

// MARK: - 提取的元數據結構

/// AI 識別的文獻元數據
struct ExtractedMetadata {
    var title: String?
    var authors: [String] = []
    var year: String?
    var journal: String?
    var doi: String?
    var entryType: String?  // 文獻類型
    
    /// 是否有任何有效資料
    var hasData: Bool {
        title != nil || !authors.isEmpty || year != nil || journal != nil || doi != nil || entryType != nil
    }
    
    /// 計算提取的信心度
    var confidence: PDFMetadataConfidence {
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
    
    /// 格式化作者為 BibTeX 格式（用 " and " 分隔）
    var authorsBibTeX: String {
        authors.joined(separator: " and ")
    }
    
    /// 文獻類型的中文名稱
    var entryTypeDisplayName: String {
        switch entryType {
        case "article": return "期刊論文"
        case "book": return "書籍"
        case "inproceedings": return "會議論文"
        case "thesis": return "碩博士論文"
        case "techreport": return "技術報告"
        case "misc": return "其他"
        default: return "未知"
        }
    }
}

/// PDF 元數據信心度（與 PDFMetadata.MetadataConfidence 相容）
enum PDFMetadataConfidence {
    case high    // 高可信度（DOI 查詢或完整資訊）
    case medium  // 中等可信度（AI 提取到大部分資訊）
    case low     // 低可信度（僅部分資訊）
}

// MARK: - 錯誤類型

enum AIError: LocalizedError {
    case notAvailable
    case generationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Apple Intelligence 不可用。請確認您的裝置支援且已啟用。"
        case .generationFailed(let message):
            return "AI 生成失敗：\(message)"
        }
    }
}
