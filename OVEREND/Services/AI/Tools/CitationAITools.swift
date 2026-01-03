//
//  CitationAITools.swift
//  OVEREND
//
//  引用 AI 工具集 - 使用 Tool Calling
//

import Foundation
import FoundationModels

// MARK: - 引用格式

@available(macOS 26.0, *)
@Generable
public enum ToolCitationStyle: String, CaseIterable, Sendable {
    case apa7 = "apa7"
    case apa6 = "apa6"
    case chicago = "chicago"
    case mla = "mla"
    case ieee = "ieee"
    case harvard = "harvard"
    
    public var displayName: String {
        switch self {
        case .apa7: return "APA 第七版"
        case .apa6: return "APA 第六版"
        case .chicago: return "Chicago"
        case .mla: return "MLA"
        case .ieee: return "IEEE"
        case .harvard: return "Harvard"
        }
    }
}

// MARK: - 問題嚴重程度

@available(macOS 26.0, *)
@Generable
public enum ToolCitationSeverity: String, CaseIterable, Sendable {
    case error = "error"
    case warning = "warning"
    case suggestion = "suggestion"
}

// MARK: - 引用格式檢查工具

@available(macOS 26.0, *)
@MainActor
public final class CheckCitationFormatTool: Tool {
    
    public let name = "checkCitationFormat"
    public let description = """
        使用此工具來回報引用格式檢查結果。
        檢查完成後，調用此工具並提供發現的問題。
        """
    
    @Generable
    public struct CitationIssue: Sendable {
        @Guide(description: "有問題的原始引用文字")
        public let original: String
        
        @Guide(description: "問題描述")
        public let description: String
        
        @Guide(description: "建議的修正")
        public let suggestion: String?
        
        @Guide(description: "問題嚴重程度")
        public let severity: ToolCitationSeverity
    }
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "發現的引用問題列表")
        public let issues: [CitationIssue]
        
        @Guide(description: "整體評估")
        public let overallAssessment: String?
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: checkCitationFormat")
        print("   - 發現問題: \(arguments.issues.count) 個")
        
        return "已檢查完成，發現 \(arguments.issues.count) 個問題"
    }
    
    public static func createSession(with tool: CheckCitationFormatTool, style: ToolCitationStyle) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是引用格式檢查專家，專精於 \(style.displayName) 格式。"
                
                """
                檢查規則：
                - 作者姓名格式
                - 年份位置和格式
                - 標點符號使用
                - et al. / 等人 的使用
                - 中英文標點區分
                """
                
                "完成後，調用 checkCitationFormat 工具回報結果。"
            }
        )
    }
}

// MARK: - 生成引用工具

@available(macOS 26.0, *)
@MainActor
public final class GenerateCitationTool: Tool {
    
    public let name = "generateCitation"
    public let description = """
        使用此工具來回報生成的引用文字。
        根據提供的書目資訊生成符合指定格式的引用。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "生成的完整引用文字")
        public let citation: String
        
        @Guide(description: "文內引用格式，如 (Author, 2024)")
        public let inTextCitation: String?
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: generateCitation")
        print("   - 引用: \(arguments.citation.prefix(50))...")
        
        return "已生成引用"
    }
    
    public static func createSession(with tool: GenerateCitationTool, style: ToolCitationStyle) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是引用格式專家，請根據 \(style.displayName) 格式生成引用。"
                
                """
                生成規則：
                - 嚴格遵循 \(style.displayName) 格式規範
                - 正確處理中英文作者姓名
                - 提供完整引用和文內引用
                """
                
                "完成後，調用 generateCitation 工具回報結果。"
            }
        )
    }
}

// MARK: - 轉換引用格式工具

@available(macOS 26.0, *)
@MainActor
public final class ConvertCitationStyleTool: Tool {
    
    public let name = "convertCitationStyle"
    public let description = """
        使用此工具來回報格式轉換後的引用。
        將引用從一種格式轉換為另一種格式。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "轉換後的引用文字")
        public let convertedCitation: String
        
        @Guide(description: "轉換過程中的注意事項")
        public let notes: [String]
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: convertCitationStyle")
        
        return "已完成格式轉換"
    }
    
    public static func createSession(
        with tool: ConvertCitationStyleTool,
        from: ToolCitationStyle,
        to: ToolCitationStyle
    ) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是引用格式轉換專家。"
                
                "將引用從 \(from.displayName) 格式轉換為 \(to.displayName) 格式。"
                
                "完成後，調用 convertCitationStyle 工具回報結果。"
            }
        )
    }
}
