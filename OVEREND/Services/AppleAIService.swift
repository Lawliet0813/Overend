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
          "title": null,
          "authors": [],
          "year": null,
          "journal": null,
          "doi": null,
          "type": "article"
        }

        📋 欄位說明：
        1. title: 從 PDF 第一頁頂部提取的真實完整標題（通常字體最大）
        2. authors: 真實作者姓名的陣列，按出現順序
        3. year: 出版年份（四位數字，範圍 1990-2025）
        4. journal: 期刊、會議或出版社的真實完整名稱
        5. doi: 只有在 PDF 中明確看到 DOI 時才填寫（格式必須是 10.開頭的數字，例如 10.1234/abcd）
        6. type: 文獻類型
           - article: 期刊論文
           - book: 書籍
           - inproceedings: 會議論文
           - thesis: 碩博士論文
           - techreport: 技術報告
           - misc: 其他

        🚫 絕對禁止：
        1. 不可填入任何說明文字（如「論文標題」、「真實作者」、「實際的 DOI（格式...）」等）
        2. 不可編造 DOI（如 10.1234/xxx）
        3. 不可使用範例值
        4. 如果 PDF 中找不到 DOI，必須設為 null（JSON 的 null，不是字串）
        5. 所有資料必須是 PDF 中實際出現的內容

        只回覆 JSON，不要其他文字。
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
            
            // 檢查是否有有效資料
            if jsonMetadata.hasData {
                // 檢查是否所有欄位都是範例值（表示 AI 完全失敗）
                let hasRealData = (jsonMetadata.title != nil && !jsonMetadata.title!.isEmpty) ||
                                  !jsonMetadata.authors.isEmpty ||
                                  jsonMetadata.year != nil ||
                                  jsonMetadata.journal != nil
                
                if hasRealData {
                    return jsonMetadata
                } else {
                    print("⚠️ JSON 解析成功但所有欄位都被過濾（可能是範例值）")
                }
            } else {
                print("⚠️ JSON 解析成功但沒有有效資料")
            }
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
            print("❌ JSON 解析失敗")
            print("原始回應: \(response.prefix(200))...")
            return nil
        }
        
        var metadata = ExtractedMetadata()
        var filteredCount = 0  // 統計被過濾的欄位數量
        
        // 提取標題（過濾範例值）
        if let title = json["title"] as? String, 
           !title.isEmpty, 
           title.lowercased() != "null" {
            if !isExampleValue(title, field: "title") {
                metadata.title = title
            } else {
                print("⚠️ 過濾範例標題: \(title)")
                filteredCount += 1
            }
        }
        
        // 提取作者
        if let authors = json["authors"] as? [String] {
            let validAuthors = authors.filter { 
                !$0.isEmpty && 
                $0.lowercased() != "null" && 
                !isExampleValue($0, field: "author") 
            }
            if validAuthors.count < authors.count {
                print("⚠️ 過濾了 \(authors.count - validAuthors.count) 個範例作者")
                filteredCount += 1
            }
            metadata.authors = validAuthors
        } else if let authorsString = json["authors"] as? String {
            // 處理 AI 返回字串而非陣列的情況
            metadata.authors = authorsString
                .components(separatedBy: CharacterSet(charactersIn: ";,，"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { 
                    !$0.isEmpty && 
                    $0.lowercased() != "null" && 
                    !isExampleValue($0, field: "author") 
                }
        }
        
        // 提取年份
        if let year = json["year"] as? String, year.count == 4 {
            metadata.year = year
        } else if let yearInt = json["year"] as? Int {
            metadata.year = String(yearInt)
        }
        
        // 提取期刊（過濾範例值）
        if let journal = json["journal"] as? String, 
           !journal.isEmpty, 
           journal.lowercased() != "null" {
            if !isExampleValue(journal, field: "journal") {
                metadata.journal = journal
            } else {
                print("⚠️ 過濾範例期刊: \(journal)")
                filteredCount += 1
            }
        }
        
        // 提取 DOI（過濾範例值）
        if let doi = json["doi"] as? String, 
           !doi.isEmpty, 
           doi.lowercased() != "null" {
            if !isExampleValue(doi, field: "doi") {
                metadata.doi = doi
            } else {
                print("⚠️ 過濾範例 DOI: \(doi)")
                filteredCount += 1
            }
        }
        
        // 提取類型
        if let type = json["type"] as? String {
            let validTypes = ["article", "book", "inproceedings", "thesis", "techreport", "misc"]
            metadata.entryType = validTypes.contains(type.lowercased()) ? type.lowercased() : "misc"
        }
        
        // 如果過濾了太多欄位，顯示警告
        if filteredCount >= 3 {
            print("⚠️ 警告：過濾了 \(filteredCount) 個範例值，AI 可能返回了 prompt 範例")
            print("   建議：檢查 PDF 前 3 頁是否包含完整資訊")
        }
        
        return metadata
    }
    
    /// 檢查是否為範例值（防止 AI 返回 prompt 中的範例）
    private func isExampleValue(_ value: String, field: String) -> Bool {
        let normalizedValue = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch field {
        case "title":
            // 檢查常見的範例標題
            let exampleTitles = ["完整標題", "論文標題", "標題", "complete title", "title"]
            return exampleTitles.contains(normalizedValue)
            
        case "author":
            // 檢查常見的範例作者
            let exampleAuthors = ["作者1", "作者2", "作者3", "作者", "author1", "author2", "author"]
            return exampleAuthors.contains(normalizedValue)
            
        case "journal":
            // 檢查常見的範例期刊名
            let exampleJournals = ["期刊名稱", "期刊或會議名稱", "會議名稱", "journal name", "conference"]
            return exampleJournals.contains(normalizedValue)
            
        case "doi":
            // 檢查範例 DOI 格式
            let exampleDOIs = ["10.xxxx/xxxxx", "10.xxxx/xxxx", "10.1234/5678"]
            if exampleDOIs.contains(normalizedValue) {
                return true
            }
            // 檢查是否包含 "xxxx" 字樣（明顯的範例值）
            if normalizedValue.contains("xxxx") || normalizedValue.contains("x") && normalizedValue.count < 15 {
                return true
            }
            return false
            
        default:
            return false
        }
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
