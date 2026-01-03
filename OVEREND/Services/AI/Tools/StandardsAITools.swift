//
//  StandardsAITools.swift
//  OVEREND
//
//  學術規範 AI 工具集 - 使用 Tool Calling
//

import Foundation
import FoundationModels

// MARK: - 問題嚴重程度

@available(macOS 26.0, *)
@Generable
public enum ToolStandardsSeverity: String, CaseIterable, Sendable {
    case critical = "critical"
    case major = "major"
    case minor = "minor"
    case suggestion = "suggestion"
    
    public var displayName: String {
        switch self {
        case .critical: return "嚴重"
        case .major: return "重要"
        case .minor: return "輕微"
        case .suggestion: return "建議"
        }
    }
}

// MARK: - 學術規範檢查工具

@available(macOS 26.0, *)
@MainActor
public final class CheckAcademicStandardsTool: Tool {
    
    public let name = "checkAcademicStandards"
    public let description = """
        使用此工具來回報學術規範檢查結果。
        檢查完成後，調用此工具並提供發現的問題。
        """
    
    @Generable
    public struct StandardsIssue: Sendable {
        @Guide(description: "問題類別（如：格式、引用、語言）")
        public let category: String
        
        @Guide(description: "問題描述")
        public let description: String
        
        @Guide(description: "問題位置或原文")
        public let location: String?
        
        @Guide(description: "建議修正")
        public let suggestion: String
        
        @Guide(description: "問題嚴重程度")
        public let severity: ToolStandardsSeverity
    }
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "發現的問題列表")
        public let issues: [StandardsIssue]
        
        @Guide(description: "整體評分（0-100）")
        public let score: Int?
        
        @Guide(description: "整體評估")
        public let overallAssessment: String?
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: checkAcademicStandards")
        print("   - 發現問題: \(arguments.issues.count) 個")
        if let score = arguments.score {
            print("   - 評分: \(score)/100")
        }
        
        return "已完成學術規範檢查，發現 \(arguments.issues.count) 個問題"
    }
    
    public static func createSession(with tool: CheckAcademicStandardsTool) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是學術寫作規範檢查專家。"
                
                """
                檢查項目：
                - 論文結構和格式
                - 引用格式規範
                - 學術語言使用
                - 邏輯連貫性
                - 客觀性和嚴謹性
                """
                
                "完成後，調用 checkAcademicStandards 工具回報結果。"
            }
        )
    }
}

// MARK: - 學術風格檢查工具

@available(macOS 26.0, *)
@MainActor
public final class CheckAcademicStyleTool: Tool {
    
    public let name = "checkAcademicStyle"
    public let description = """
        使用此工具來回報學術風格檢查結果。
        檢查完成後，調用此工具並提供風格問題。
        """
    
    @Generable
    public struct StyleIssue: Sendable {
        @Guide(description: "原始文字")
        public let original: String
        
        @Guide(description: "建議修正")
        public let suggestion: String
        
        @Guide(description: "修正原因")
        public let reason: String
        
        @Guide(description: "嚴重程度")
        public let severity: ToolStandardsSeverity
    }
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "發現的風格問題列表")
        public let issues: [StyleIssue]
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: checkAcademicStyle")
        print("   - 風格問題: \(arguments.issues.count) 個")
        
        return "已完成風格檢查，發現 \(arguments.issues.count) 個問題"
    }
    
    public static func createSession(with tool: CheckAcademicStyleTool) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是學術寫作風格專家。"
                
                """
                檢查項目：
                - 口語化表達：我覺得 → 研究顯示
                - 第一人稱：我們發現 → 研究發現
                - 主觀用語：很明顯 → 由此可見
                - 不夠正式：大家都知道 → 普遍認為
                """
                
                "完成後，調用 checkAcademicStyle 工具回報結果。"
            }
        )
    }
}
