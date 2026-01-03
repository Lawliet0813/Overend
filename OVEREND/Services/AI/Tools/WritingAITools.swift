//
//  WritingAITools.swift
//  OVEREND
//
//  寫作 AI 工具集 - 使用 Tool Calling
//

import Foundation
import FoundationModels

// MARK: - 寫作分析工具

/// 寫作分析工具
@available(macOS 26.0, *)
@MainActor
public final class AnalyzeWritingTool: Tool {
    
    public let name = "analyzeWriting"
    public let description = """
        使用此工具來回報寫作分析結果。
        分析完文字內容後，調用此工具並提供語法、風格和邏輯問題。
        """
    
    /// 問題嚴重程度
    @Generable
    public enum IssueSeverity: String, CaseIterable, Sendable {
        case high = "high"
        case medium = "medium"
        case low = "low"
    }
    
    /// 單一問題
    @Generable
    public struct WritingIssue: Sendable {
        @Guide(description: "問題的原始文字")
        public let original: String
        
        @Guide(description: "建議的修正")
        public let suggestion: String
        
        @Guide(description: "問題說明")
        public let explanation: String
        
        @Guide(description: "問題嚴重程度")
        public let severity: IssueSeverity
    }
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "語法問題列表")
        public let grammarIssues: [WritingIssue]
        
        @Guide(description: "風格問題列表")
        public let styleIssues: [WritingIssue]
        
        @Guide(description: "邏輯問題列表")
        public let logicIssues: [WritingIssue]
        
        @Guide(description: "整體評價和改進建議")
        public let overallFeedback: String
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        let totalIssues = arguments.grammarIssues.count + 
                          arguments.styleIssues.count + 
                          arguments.logicIssues.count
        
        print("🔧 Tool Called: analyzeWriting")
        print("   - 語法問題: \(arguments.grammarIssues.count) 個")
        print("   - 風格問題: \(arguments.styleIssues.count) 個")
        print("   - 邏輯問題: \(arguments.logicIssues.count) 個")
        
        return "已分析完成，發現 \(totalIssues) 個問題"
    }
    
    public static func createSession(with tool: AnalyzeWritingTool, academicMode: Bool = true) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是專業的寫作分析專家。"
                
                "分析用戶提供的文字，檢查語法、風格和邏輯問題。"
                
                if academicMode {
                    """
                    學術寫作規範：
                    - 使用第三人稱或被動語態
                    - 避免口語化表達
                    - 確保論述邏輯清晰
                    - 使用適當的學術連接詞
                    """
                }
                
                """
                分析完成後，調用 analyzeWriting 工具回報：
                - grammarIssues: 語法和標點問題
                - styleIssues: 表達風格問題
                - logicIssues: 邏輯連貫性問題
                - overallFeedback: 整體評價
                """
                
                "使用繁體中文回覆。"
            }
        )
    }
}

// MARK: - 文字改寫工具

/// 改寫風格
@available(macOS 26.0, *)
@Generable
public enum ToolRewriteStyle: String, CaseIterable, Sendable {
    case formal = "formal"           // 正式
    case academic = "academic"       // 學術
    case concise = "concise"         // 精簡
    case elaborate = "elaborate"     // 詳細
    case neutral = "neutral"         // 中立
}

/// 文字改寫工具
@available(macOS 26.0, *)
@MainActor
public final class RewriteTextTool: Tool {
    
    public let name = "rewriteText"
    public let description = """
        使用此工具來回報改寫後的文字。
        完成文字改寫後，調用此工具並提供結果。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "改寫後的文字")
        public let rewrittenText: String
        
        @Guide(description: "主要修改說明")
        public let changes: [String]
    }
    
    public private(set) var result: (text: String, changes: [String])?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = (text: arguments.rewrittenText, changes: arguments.changes)
        
        print("🔧 Tool Called: rewriteText")
        print("   - 改寫後長度: \(arguments.rewrittenText.count) 字")
        print("   - 修改項目: \(arguments.changes.count) 項")
        
        return "已完成改寫"
    }
    
    public static func createSession(with tool: RewriteTextTool, style: ToolRewriteStyle) -> LanguageModelSession {
        let styleDescription: String = {
            switch style {
            case .formal: return "正式、專業"
            case .academic: return "學術、嚴謹"
            case .concise: return "精簡、扼要"
            case .elaborate: return "詳細、完整"
            case .neutral: return "中立、客觀"
            }
        }()
        
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是專業的文字編輯專家。"
                
                "將用戶提供的文字改寫為「\(styleDescription)」風格。"
                
                """
                改寫規則：
                - 保持原意不變
                - 調整語氣和用詞
                - 使用繁體中文
                """
                
                "完成後，調用 rewriteText 工具回報結果。"
            }
        )
    }
}
