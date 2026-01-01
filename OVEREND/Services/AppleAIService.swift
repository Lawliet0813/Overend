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
                let session = LanguageModelSession()
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
    
    // MARK: - 文獻元數據識別
    
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
        請分析以下學術文獻的文字內容，識別並提取元數據資訊。

        文獻內容：
        ---
        \(truncatedText)
        ---

        請提取以下資訊（如果無法識別則留空）：
        1. 標題（Title）：文獻的完整標題
        2. 作者（Authors）：所有作者姓名，用分號 ; 分隔
        3. 年份（Year）：發表年份（4位數字）
        4. 期刊/來源（Journal）：期刊名稱或出版來源
        5. DOI：如果有的話

        請以下列格式回覆，每行一個欄位：
        標題: [標題內容]
        作者: [作者1; 作者2; 作者3]
        年份: [YYYY]
        期刊: [期刊名稱]
        DOI: [DOI]
        
        只回覆上述格式，不要其他說明文字。如果某欄位無法識別，請寫「未知」。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return parseMetadataResponse(response.content)
        } catch {
            throw AIError.generationFailed(error.localizedDescription)
        }
    }
    
    /// 解析 AI 回應的元數據
    private func parseMetadataResponse(_ response: String) -> ExtractedMetadata {
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
    
    /// 是否有任何有效資料
    var hasData: Bool {
        title != nil || !authors.isEmpty || year != nil || journal != nil || doi != nil
    }
    
    /// 格式化作者為 BibTeX 格式（用 " and " 分隔）
    var authorsBibTeX: String {
        authors.joined(separator: " and ")
    }
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
