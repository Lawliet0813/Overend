//
//  AgentTools.swift
//  OVEREND
//
//  Agent 專用 Tool Calling 工具集
//

import Foundation
import FoundationModels

// MARK: - 文獻分析工具

/// 文獻分析工具 - 深度分析單篇文獻
@available(macOS 26.0, *)
@MainActor
public final class AnalyzeLiteratureTool: Tool {
    
    public let name = "analyzeLiterature"
    public let description = """
        使用此工具來回報文獻的深度分析結果。
        分析文獻的主題、方法論、貢獻與限制。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "文獻的主要研究主題")
        public let mainTopic: String
        
        @Guide(description: "使用的研究方法論")
        public let methodology: String?
        
        @Guide(description: "主要學術貢獻，列出 2-4 點")
        public let contributions: [String]
        
        @Guide(description: "研究的限制或不足")
        public let limitations: [String]?
        
        @Guide(description: "建議的標籤列表")
        public let suggestedTags: [String]
        
        @Guide(description: "建議的分類")
        public let suggestedCategory: String
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: analyzeLiterature")
        print("   - 主題: \(arguments.mainTopic)")
        print("   - 貢獻: \(arguments.contributions.count) 點")
        print("   - 標籤: \(arguments.suggestedTags.joined(separator: ", "))")
        
        return "分析完成"
    }
    
    public static func createSession(with tool: AnalyzeLiteratureTool) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是學術文獻分析專家。"
                
                "深度分析用戶提供的學術文獻内容。"
                
                """
                分析項目：
                - 主要研究主題
                - 研究方法論
                - 學術貢獻（2-4 點）
                - 研究限制
                - 建議標籤（5-8 個）
                - 建議分類
                """
                
                "使用繁體中文。完成分析後，調用 analyzeLiterature 工具回報結果。"
            }
        )
    }
}

// MARK: - 批次分類工具

/// 批次分類工具 - 為多篇文獻建議分類
@available(macOS 26.0, *)
@MainActor
public final class BatchClassifyTool: Tool {
    
    public let name = "batchClassify"
    public let description = """
        使用此工具來回報多篇文獻的分類建議。
        為每篇文獻建議最適合的分組。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "每篇文獻的分類建議列表")
        public let classifications: [ClassificationItem]
        
        @Guide(description: "建議新增的分組（如果現有分組不足）")
        public let newGroupSuggestions: [String]?
        
        @Guide(description: "分類的整體邏輯說明")
        public let rationale: String
    }
    
    @Generable
    public struct ClassificationItem: Sendable {
        @Guide(description: "文獻標題")
        public let title: String
        
        @Guide(description: "建議的分類名稱")
        public let category: String
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: batchClassify")
        print("   - 分類數量: \(arguments.classifications.count)")
        if let newGroups = arguments.newGroupSuggestions {
            print("   - 新分組建議: \(newGroups.joined(separator: ", "))")
        }
        
        return "分類建議完成"
    }
    
    public static func createSession(
        with tool: BatchClassifyTool,
        existingGroups: [String],
        literatureTitles: [String]
    ) -> LanguageModelSession {
        let groupList = existingGroups.isEmpty ? "（目前沒有現有分組，可建議新分組）" : existingGroups.joined(separator: "、")
        let titleList = literatureTitles.joined(separator: "\n- ")
        
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是文獻分類專家。"
                
                "為以下文獻建議適當的分類。"
                
                "現有分組：\(groupList)"
                
                "待分類文獻：\n- \(titleList)"
                
                """
                分類規則：
                - 優先使用現有分組
                - 如需新分組，使用簡潔的中文名稱
                - 每篇文獻只建議一個最適合的分類
                - 提供分類邏輯說明
                """
                
                "完成分析後，調用 batchClassify 工具回報結果。"
            }
        )
    }
}


// MARK: - 智慧標籤工具

/// 智慧標籤工具 - 自動產生標籤建議
@available(macOS 26.0, *)
@MainActor
public final class SmartTagTool: Tool {
    
    public let name = "smartTag"
    public let description = """
        使用此工具來回報智慧標籤建議。
        分析文獻內容，產生相關的標籤。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "建議的標籤列表，每個標籤附帶相關度分數 (0-1)")
        public let tags: [TagSuggestion]
        
        @Guide(description: "標籤的主題分佈說明")
        public let topicDistribution: String?
    }
    
    @Generable
    public struct TagSuggestion: Sendable {
        @Guide(description: "標籤名稱")
        public let name: String
        
        @Guide(description: "相關度分數 (0-1)")
        public let relevance: Double
        
        @Guide(description: "標籤類型：topic（主題）、method（方法）、field（領域）")
        public let type: String
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: smartTag")
        print("   - 標籤數量: \(arguments.tags.count)")
        for tag in arguments.tags.prefix(5) {
            print("   - \(tag.name) (\(tag.type)): \(String(format: "%.2f", tag.relevance))")
        }
        
        return "標籤建議完成"
    }
    
    public static func createSession(
        with tool: SmartTagTool,
        existingTags: [String]
    ) -> LanguageModelSession {
        let tagList = existingTags.isEmpty ? "（目前沒有現有標籤）" : existingTags.joined(separator: "、")
        
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是學術文獻標籤專家。"
                
                "分析文獻內容，產生相關的標籤建議。"
                
                "現有標籤：\(tagList)"
                
                """
                標籤規則：
                - 產生 5-10 個標籤
                - 包含不同類型：topic（主題）、method（方法）、field（領域）
                - 為每個標籤評估相關度 (0-1)
                - 優先使用現有標籤
                - 使用繁體中文
                """
                
                "完成分析後，調用 smartTag 工具回報結果。"
            }
        )
    }
}

// MARK: - 整理計畫工具

/// 整理計畫工具 - 生成文獻庫整理建議
@available(macOS 26.0, *)
@MainActor
public final class OrganizePlanTool: Tool {
    
    public let name = "organizePlan"
    public let description = """
        使用此工具來回報文獻庫整理計畫。
        分析文獻庫狀態，提出整理建議。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "建議的分組結構")
        public let suggestedStructure: [GroupStructure]
        
        @Guide(description: "需要處理的問題")
        public let issues: [String]
        
        @Guide(description: "整理優先順序建議")
        public let priorities: [String]
        
        @Guide(description: "預估所需時間（分鐘）")
        public let estimatedMinutes: Int
    }
    
    @Generable
    public struct GroupStructure: Sendable {
        @Guide(description: "分組名稱")
        public let name: String
        
        @Guide(description: "子分組（如有）")
        public let children: [String]?
        
        @Guide(description: "預估包含的文獻數量")
        public let estimatedCount: Int
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: organizePlan")
        print("   - 建議分組: \(arguments.suggestedStructure.count) 個")
        print("   - 發現問題: \(arguments.issues.count) 個")
        print("   - 預估時間: \(arguments.estimatedMinutes) 分鐘")
        
        return "整理計畫完成"
    }
    
    public static func createSession(
        with tool: OrganizePlanTool,
        libraryStats: LibraryStats
    ) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是文獻庫整理專家。"
                
                "分析文獻庫狀態，提出整理建議。"
                
                """
                文獻庫統計：
                - 總文獻數：\(libraryStats.totalEntries)
                - 未分類數：\(libraryStats.unclassifiedCount)
                - 現有分組：\(libraryStats.groupNames.joined(separator: "、"))
                - 現有標籤：\(libraryStats.tagNames.joined(separator: "、"))
                """
                
                """
                整理規則：
                - 建議合理的分組結構（不超過 10 個主分組）
                - 識別需要處理的問題（重複、空分組等）
                - 按優先順序排列任務
                - 預估合理的處理時間
                """
                
                "完成分析後，調用 organizePlan 工具回報結果。"
            }
        )
    }
}

// MARK: - 輔助結構

/// 文獻庫統計
public struct LibraryStats {
    public let totalEntries: Int
    public let unclassifiedCount: Int
    public let groupNames: [String]
    public let tagNames: [String]
    
    public init(
        totalEntries: Int,
        unclassifiedCount: Int,
        groupNames: [String],
        tagNames: [String]
    ) {
        self.totalEntries = totalEntries
        self.unclassifiedCount = unclassifiedCount
        self.groupNames = groupNames
        self.tagNames = tagNames
    }
}
