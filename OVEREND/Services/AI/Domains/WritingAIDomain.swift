//
//  WritingAIDomain.swift
//  OVEREND
//
//  寫作 AI 領域 - 整合所有寫作相關的 AI 功能
//
//  整合來源：
//  - AppleAIService.getWritingSuggestions()
//  - AICommandExecutor 寫作相關指令
//  - TaiwanAcademicStandardsService.checkStyle()
//

import Foundation
import AppKit
import FoundationModels

// MARK: - 寫作選項

/// 寫作建議選項
public struct WritingOptions {
    public var checkGrammar: Bool = true          // 檢查語法
    public var checkStyle: Bool = true            // 檢查風格
    public var checkLogic: Bool = true            // 檢查邏輯
    public var academicMode: Bool = true          // 學術模式
    public var language: WritingLanguage = .traditionalChinese
    
    public init() {}
    
    public enum WritingLanguage: String {
        case traditionalChinese = "zh-TW"
        case english = "en"
    }
}

/// 改寫風格
public enum RewriteStyle: String, CaseIterable {
    case formal = "formal"           // 正式
    case academic = "academic"       // 學術
    case concise = "concise"         // 精簡
    case elaborate = "elaborate"     // 詳細
    case neutral = "neutral"         // 中立客觀
    
    var displayName: String {
        switch self {
        case .formal: return "正式"
        case .academic: return "學術"
        case .concise: return "精簡"
        case .elaborate: return "詳細"
        case .neutral: return "中立客觀"
        }
    }
    
    var promptInstruction: String {
        switch self {
        case .formal:
            return "使用正式的書面語表達"
        case .academic:
            return "使用學術寫作風格，客觀嚴謹"
        case .concise:
            return "精簡表達，去除冗贅"
        case .elaborate:
            return "詳細闡述，增加說明"
        case .neutral:
            return "使用中立客觀的語氣"
        }
    }
}

// MARK: - 寫作建議結果

/// 寫作建議
public struct WritingSuggestions {
    public let grammarIssues: [GrammarIssue]
    public let styleIssues: [StyleIssue]
    public let logicIssues: [LogicIssue]
    public let overallFeedback: String
    
    public var hasIssues: Bool {
        !grammarIssues.isEmpty || !styleIssues.isEmpty || !logicIssues.isEmpty
    }
    
    public var totalIssueCount: Int {
        grammarIssues.count + styleIssues.count + logicIssues.count
    }
}

/// 語法問題
public struct GrammarIssue: Identifiable {
    public let id = UUID()
    public let original: String
    public let suggestion: String
    public let explanation: String
}

/// 風格問題
public struct StyleIssue: Identifiable {
    public let id = UUID()
    public let original: String
    public let suggestion: String
    public let reason: String
    public let severity: IssueSeverity
    
    public enum IssueSeverity: String {
        case high = "high"
        case medium = "medium"
        case low = "low"
    }
}

/// 邏輯問題
public struct LogicIssue: Identifiable {
    public let id = UUID()
    public let description: String
    public let suggestion: String
}

// MARK: - 寫作 AI 領域

/// 寫作 AI 領域
@available(macOS 26.0, *)
@MainActor
public class WritingAIDomain {
    
    private weak var service: UnifiedAIService?
    
    init(service: UnifiedAIService) {
        self.service = service
    }
    
    // MARK: - 寫作建議
    
    /// 取得寫作建議（使用 Tool Calling）
    /// - Parameters:
    ///   - text: 要檢查的文字
    ///   - options: 檢查選項
    /// - Returns: 寫作建議
    public func getSuggestions(for text: String, options: WritingOptions = WritingOptions()) async throws -> WritingSuggestions {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !text.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let truncatedText = String(text.prefix(3000))
        
        // 策略 1: Tool Calling
        do {
            let tool = AnalyzeWritingTool()
            let session = AnalyzeWritingTool.createSession(with: tool, academicMode: options.academicMode)
            
            let prompt = """
            請分析以下\(options.academicMode ? "學術" : "")寫作內容：
            
            ---
            \(truncatedText)
            ---
            """
            
            let _ = try await session.respond(to: prompt)
            
            if let result = tool.result {
                print("✅ Tool Calling 寫作分析成功")
                
                // 轉換結果
                let grammarIssues = result.grammarIssues.map { issue in
                    GrammarIssue(
                        original: issue.original,
                        suggestion: issue.suggestion,
                        explanation: issue.explanation
                    )
                }
                
                let styleIssues = result.styleIssues.map { issue in
                    let severity: StyleIssue.IssueSeverity
                    switch issue.severity {
                    case .high: severity = .high
                    case .low: severity = .low
                    default: severity = .medium
                    }
                    return StyleIssue(
                        original: issue.original,
                        suggestion: issue.suggestion,
                        reason: issue.explanation,
                        severity: severity
                    )
                }
                
                let logicIssues = result.logicIssues.map { issue in
                    LogicIssue(
                        description: issue.original,
                        suggestion: issue.suggestion
                    )
                }
                
                return WritingSuggestions(
                    grammarIssues: grammarIssues,
                    styleIssues: styleIssues,
                    logicIssues: logicIssues,
                    overallFeedback: result.overallFeedback
                )
            }
        } catch {
            print("⚠️ Tool Calling 失敗: \(error.localizedDescription)，降級到 Prompt 方式")
        }
        
        // 策略 2: Prompt 方式降級
        let session = service.createSession()
        
        let prompt = """
        請審閱以下\(options.academicMode ? "學術" : "")寫作內容，並提供改進建議。
        
        ---
        \(truncatedText)
        ---
        
        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        {
          "grammarIssues": [
            {"original": "原文", "suggestion": "修正", "explanation": "說明"}
          ],
          "styleIssues": [
            {"original": "原文", "suggestion": "建議", "reason": "原因", "severity": "medium"}
          ],
          "logicIssues": [
            {"description": "問題描述", "suggestion": "建議"}
          ],
          "overallFeedback": "整體評價"
        }
        
        檢查項目：
        \(options.checkGrammar ? "- 語法和標點符號" : "")
        \(options.checkStyle ? "- 表達風格\(options.academicMode ? "（學術寫作規範）" : "")" : "")
        \(options.checkLogic ? "- 邏輯連貫性" : "")
        
        使用繁體中文回覆。如果沒有問題，相應陣列留空。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseSuggestionsResponse(response.content)
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.writingSuggestionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 學術風格檢查
    
    /// 檢查學術寫作風格
    /// - Parameter text: 要檢查的文字
    /// - Returns: 風格問題列表
    public func checkAcademicStyle(text: String) async throws -> [StyleIssue] {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !text.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        let truncatedText = String(text.prefix(4000))
        
        let prompt = """
        請檢查以下繁體中文學術文本的行文風格問題。
        
        文本：
        ---
        \(truncatedText)
        ---
        
        請檢查以下項目：
        1. 第一人稱使用（學術寫作應避免「我」、「我們」）
        2. 口語化表達（應使用正式書面語）
        3. 主觀判斷詞彙（如「很好」、「很棒」應改為客觀描述）
        4. 冗贅表達（可以精簡的句子）
        5. 學術嚴謹性（避免過度推論、絕對化陳述）
        
        建議的學術表達替換：
        - 我認為 → 本研究認為 / 研究者認為
        - 我們發現 → 研究發現 / 結果顯示
        - 很明顯 → 由此可見 / 顯示
        - 大家都知道 → 普遍認為 / 學界共識
        
        請以 JSON 格式回覆（不要包含 markdown 程式碼區塊符號```）：
        [
          {
            "original": "原始文字",
            "suggestion": "建議修正",
            "reason": "修正原因",
            "severity": "medium"
          }
        ]
        
        severity 可選值：high, medium, low
        如果沒有問題，回覆空陣列 []
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return try parseStyleIssuesResponse(response.content)
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.writingSuggestionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 改寫文字
    
    /// 改寫文字
    /// - Parameters:
    ///   - text: 原始文字
    ///   - style: 改寫風格
    /// - Returns: 改寫後的文字
    public func rewrite(text: String, style: RewriteStyle) async throws -> String {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !text.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        let prompt = """
        請改寫以下文字，\(style.promptInstruction)。
        
        原文：
        ---
        \(text)
        ---
        
        要求：
        1. 保持原意不變
        2. \(style.promptInstruction)
        3. 使用繁體中文
        4. 保持專業術語
        
        只回覆改寫後的文字，不要其他說明。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw AIServiceError.writingSuggestionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 精簡文字
    
    /// 精簡文字
    /// - Parameters:
    ///   - text: 原始文字
    ///   - targetRatio: 目標長度比例（0.5 = 縮短到 50%）
    /// - Returns: 精簡後的文字
    public func condense(text: String, targetRatio: Double = 0.7) async throws -> String {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !text.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        let targetLength = Int(Double(text.count) * targetRatio)
        
        let prompt = """
        請精簡以下文字，目標長度約 \(targetLength) 字（原文 \(text.count) 字）。
        
        原文：
        ---
        \(text)
        ---
        
        要求：
        1. 保留核心論點和重要資訊
        2. 刪除冗贅的修飾語和重複內容
        3. 保持邏輯連貫性
        4. 使用繁體中文
        
        只回覆精簡後的文字，不要其他說明。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw AIServiceError.writingSuggestionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 私有方法
    
    private func parseSuggestionsResponse(_ response: String) throws -> WritingSuggestions {
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
            // 返回默認值
            return WritingSuggestions(
                grammarIssues: [],
                styleIssues: [],
                logicIssues: [],
                overallFeedback: response
            )
        }
        
        // 解析語法問題
        var grammarIssues: [GrammarIssue] = []
        if let grammarArray = json["grammarIssues"] as? [[String: String]] {
            grammarIssues = grammarArray.compactMap { dict in
                guard let original = dict["original"],
                      let suggestion = dict["suggestion"] else { return nil }
                return GrammarIssue(
                    original: original,
                    suggestion: suggestion,
                    explanation: dict["explanation"] ?? ""
                )
            }
        }
        
        // 解析風格問題
        var styleIssues: [StyleIssue] = []
        if let styleArray = json["styleIssues"] as? [[String: String]] {
            styleIssues = styleArray.compactMap { dict in
                guard let original = dict["original"],
                      let suggestion = dict["suggestion"] else { return nil }
                let severityStr = dict["severity"] ?? "medium"
                let severity: StyleIssue.IssueSeverity
                switch severityStr {
                case "high": severity = .high
                case "low": severity = .low
                default: severity = .medium
                }
                return StyleIssue(
                    original: original,
                    suggestion: suggestion,
                    reason: dict["reason"] ?? "",
                    severity: severity
                )
            }
        }
        
        // 解析邏輯問題
        var logicIssues: [LogicIssue] = []
        if let logicArray = json["logicIssues"] as? [[String: String]] {
            logicIssues = logicArray.compactMap { dict in
                guard let description = dict["description"] else { return nil }
                return LogicIssue(
                    description: description,
                    suggestion: dict["suggestion"] ?? ""
                )
            }
        }
        
        let overallFeedback = json["overallFeedback"] as? String ?? ""
        
        return WritingSuggestions(
            grammarIssues: grammarIssues,
            styleIssues: styleIssues,
            logicIssues: logicIssues,
            overallFeedback: overallFeedback
        )
    }
    
    private func parseStyleIssuesResponse(_ response: String) throws -> [StyleIssue] {
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let jsonStart = cleanedResponse.firstIndex(of: "["),
           let jsonEnd = cleanedResponse.lastIndex(of: "]") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        guard let data = cleanedResponse.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }
        
        return jsonArray.compactMap { dict in
            guard let original = dict["original"],
                  let suggestion = dict["suggestion"] else { return nil }
            let severityStr = dict["severity"] ?? "medium"
            let severity: StyleIssue.IssueSeverity
            switch severityStr {
            case "high": severity = .high
            case "low": severity = .low
            default: severity = .medium
            }
            return StyleIssue(
                original: original,
                suggestion: suggestion,
                reason: dict["reason"] ?? "",
                severity: severity
            )
        }
    }
}
