//
//  DocumentAITools.swift
//  OVEREND
//
//  文件處理 AI 工具集 - 使用 Tool Calling
//

import Foundation
import FoundationModels

// MARK: - 摘要生成工具

/// 文獻摘要生成工具
@available(macOS 26.0, *)
@MainActor
public final class GenerateSummaryTool: Tool {
    
    public let name = "generateSummary"
    public let description = """
        使用此工具來回報生成的文獻摘要。
        分析完文獻內容後，調用此工具並提供摘要結果。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "生成的中文摘要，約 100-150 字，保持學術風格")
        public let summary: String
        
        @Guide(description: "摘要涵蓋的主要重點，列出 3-5 個要點")
        public let keyPoints: [String]
    }
    
    public private(set) var result: (summary: String, keyPoints: [String])?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = (summary: arguments.summary, keyPoints: arguments.keyPoints)
        
        print("🔧 Tool Called: generateSummary")
        print("   - 摘要長度: \(arguments.summary.count) 字")
        print("   - 重點數量: \(arguments.keyPoints.count) 個")
        
        return "已生成摘要，共 \(arguments.summary.count) 字"
    }
    
    public static func createSession(with tool: GenerateSummaryTool) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是學術文獻摘要專家。"
                
                "分析用戶提供的文獻內容，生成簡潔的中文摘要。"
                
                """
                摘要規則：
                - 長度：100-150 字
                - 語言：繁體中文
                - 風格：學術、客觀
                - 重點：提取 3-5 個主要論點
                """
                
                "完成後，調用 generateSummary 工具回報結果。"
            }
        )
    }
}

// MARK: - 關鍵詞提取工具

/// 關鍵詞提取工具
@available(macOS 26.0, *)
@MainActor
public final class ExtractKeywordsTool: Tool {
    
    public let name = "extractKeywords"
    public let description = """
        使用此工具來回報從文獻中提取的關鍵詞。
        分析完文獻內容後，調用此工具並提供關鍵詞列表。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "從文獻中提取的關鍵詞列表，5-8 個詞")
        public let keywords: [String]
        
        @Guide(description: "文獻的主要學科領域")
        public let field: String?
    }
    
    public private(set) var result: (keywords: [String], field: String?)?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = (keywords: arguments.keywords, field: arguments.field)
        
        print("🔧 Tool Called: extractKeywords")
        print("   - 關鍵詞: \(arguments.keywords.joined(separator: ", "))")
        if let field = arguments.field {
            print("   - 領域: \(field)")
        }
        
        return "已提取 \(arguments.keywords.count) 個關鍵詞"
    }
    
    public static func createSession(with tool: ExtractKeywordsTool) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是學術文獻關鍵詞提取專家。"
                
                "分析用戶提供的文獻內容，提取核心關鍵詞。"
                
                """
                提取規則：
                - 數量：5-8 個關鍵詞
                - 語言：使用繁體中文
                - 選擇：優先選擇專業術語和核心概念
                - 避免：過於寬泛或不具代表性的詞彙
                """
                
                "完成後，調用 extractKeywords 工具回報結果。"
            }
        )
    }
}

// MARK: - 分類建議工具

/// 文獻分類建議工具
@available(macOS 26.0, *)
@MainActor
public final class SuggestCategoriesTool: Tool {
    
    public let name = "suggestCategories"
    public let description = """
        使用此工具來回報建議的文獻分類。
        分析完文獻內容後，調用此工具並提供分類建議。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "建議的分類名稱列表，1-3 個")
        public let categories: [String]
        
        @Guide(description: "選擇這些分類的理由")
        public let rationale: String?
    }
    
    public private(set) var result: (categories: [String], rationale: String?)?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = (categories: arguments.categories, rationale: arguments.rationale)
        
        print("🔧 Tool Called: suggestCategories")
        print("   - 分類: \(arguments.categories.joined(separator: ", "))")
        
        return "已建議 \(arguments.categories.count) 個分類"
    }
    
    public static func createSession(with tool: SuggestCategoriesTool, existingGroups: [String]) -> LanguageModelSession {
        let groupList = existingGroups.isEmpty ? "（目前沒有現有分組）" : existingGroups.joined(separator: "、")
        
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是文獻分類專家。"
                
                "根據文獻內容建議適合的分類名稱。"
                
                "現有分組：\(groupList)"
                
                """
                分類規則：
                - 數量：1-3 個分類
                - 優先使用現有分組
                - 如需新分組，使用簡潔的中文名稱
                """
                
                "完成分析後，調用 suggestCategories 工具回報結果。"
            }
        )
    }
}
