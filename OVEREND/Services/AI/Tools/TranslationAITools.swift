//
//  TranslationAITools.swift
//  OVEREND
//
//  翻譯 AI 工具集 - 使用 Tool Calling
//

import Foundation
import FoundationModels

// MARK: - 翻譯語言

@available(macOS 26.0, *)
@Generable
public enum ToolTranslationLanguage: String, CaseIterable, Sendable {
    case chinese = "zh-TW"
    case english = "en"
    
    public var displayName: String {
        switch self {
        case .chinese: return "繁體中文"
        case .english: return "英文"
        }
    }
}

// MARK: - 學術翻譯工具

@available(macOS 26.0, *)
@MainActor
public final class TranslateAcademicTool: Tool {
    
    public let name = "translateAcademic"
    public let description = """
        使用此工具來回報學術翻譯結果。
        完成翻譯後，調用此工具並提供翻譯文字和術語說明。
        """
    
    @Generable
    public struct TermNote: Sendable {
        @Guide(description: "原文術語")
        public let term: String
        
        @Guide(description: "翻譯說明")
        public let explanation: String
    }
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "翻譯後的文字")
        public let translatedText: String
        
        @Guide(description: "重要術語的翻譯說明，3-5 個")
        public let termNotes: [TermNote]
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: translateAcademic")
        print("   - 翻譯長度: \(arguments.translatedText.count) 字")
        print("   - 術語說明: \(arguments.termNotes.count) 個")
        
        return "已完成翻譯，共 \(arguments.translatedText.count) 字"
    }
    
    public static func createSession(
        with tool: TranslateAcademicTool,
        from: ToolTranslationLanguage,
        to: ToolTranslationLanguage
    ) -> LanguageModelSession {
        let direction = from == .chinese ? "中文翻譯為英文" : "英文翻譯為繁體中文"
        
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是專業的學術翻譯專家，專精於\(direction)。"
                
                """
                翻譯規則：
                - 保持學術文體的正式性
                - 正確使用專業術語
                - 維持原文的邏輯結構
                - 提供重要術語的翻譯說明
                """
                
                "完成後，調用 translateAcademic 工具回報結果。"
            }
        )
    }
}

// MARK: - 術語建議工具

@available(macOS 26.0, *)
@MainActor
public final class SuggestTermTranslationTool: Tool {
    
    public let name = "suggestTermTranslation"
    public let description = """
        使用此工具來回報術語翻譯建議。
        分析完術語後，調用此工具並提供翻譯選項。
        """
    
    @Generable
    public struct TranslationOption: Sendable {
        @Guide(description: "翻譯選項")
        public let translation: String
        
        @Guide(description: "使用情境說明")
        public let usage: String?
        
        @Guide(description: "來源或參考")
        public let source: String?
    }
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "術語翻譯選項列表")
        public let options: [TranslationOption]
        
        @Guide(description: "推薦的翻譯選項索引（從 0 開始）")
        public let recommendedIndex: Int?
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: suggestTermTranslation")
        print("   - 選項數: \(arguments.options.count) 個")
        
        return "已提供 \(arguments.options.count) 個翻譯選項"
    }
    
    public static func createSession(with tool: SuggestTermTranslationTool, field: String?) -> LanguageModelSession {
        let fieldContext = field.map { "這是\($0)領域的術語。" } ?? ""
        
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是學術術語翻譯專家。"
                
                fieldContext
                
                """
                請提供：
                - 2-4 個翻譯選項
                - 每個選項的使用情境
                - 推薦的選項
                """
                
                "完成後，調用 suggestTermTranslation 工具回報結果。"
            }
        )
    }
}
