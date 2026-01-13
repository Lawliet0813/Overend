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
    
    /// 建立用於寫作分析的 Session
    /// 
    /// 基於 tw-function-call-reasoning-10k 資料集分析優化的推理模式
    public static func createSession(with tool: AnalyzeWritingTool, academicMode: Bool = true) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是專業的寫作分析專家。"
                
                """
                📋 推理步驟（Chain-of-Thought）：
                
                1. 首先，通讀整段文字，理解整體內容和語境。
                
                2. 然後，檢查語法問題：
                   - 標點符號使用是否正確
                   - 句子結構是否完整
                   - 主謂賓是否搭配
                
                3. 接著，檢查風格問題：
                   - 是否有口語化表達
                   - 是否有不當的人稱使用
                   - 用詞是否恰當
                
                4. 最後，檢查邏輯問題：
                   - 論述是否連貫
                   - 因果關係是否清晰
                   - 是否有矛盾之處
                """
                
                if academicMode {
                    """
                    學術寫作規範：
                    - 使用第三人稱或被動語態（避免「我認為」「我們發現」）
                    - 避免口語化表達（如「很棒」「不錯」）
                    - 確保論述邏輯清晰
                    - 使用適當的學術連接詞
                    """
                }
                
                """
                📝 範例（Few-shot）：
                
                範例 1 - 學術寫作分析：
                輸入：「我認為這個研究很棒，結果證明我們的假設是對的。」
                思考：這段文字有幾個學術寫作問題：
                      1. 使用第一人稱「我」「我們」
                      2. 口語化表達「很棒」
                      3. 過於主觀的判斷
                結果：
                - styleIssues: [
                    {original: "我認為", suggestion: "本研究認為", explanation: "學術寫作應避免第一人稱", severity: "high"},
                    {original: "很棒", suggestion: "具有重要意義", explanation: "應使用客觀學術用語", severity: "medium"},
                    {original: "我們的", suggestion: "本研究的", explanation: "使用第三人稱表述", severity: "high"}
                  ]
                - overallFeedback: "文字整體流暢，但需調整為學術寫作風格"
                
                範例 2 - 無問題情況：
                輸入：「本研究透過實證分析驗證了假設，結果顯示變數間存在顯著相關。」
                思考：這段文字符合學術寫作規範：使用第三人稱、客觀描述、邏輯清晰。
                結果：
                - grammarIssues: []
                - styleIssues: []
                - logicIssues: []
                - overallFeedback: "文字符合學術寫作規範，表達清晰專業"
                """
                
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
