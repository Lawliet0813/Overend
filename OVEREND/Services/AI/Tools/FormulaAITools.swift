//
//  FormulaAITools.swift
//  OVEREND
//
//  公式 AI 工具集 - 使用 Tool Calling
//

import Foundation
import FoundationModels

// MARK: - 公式解釋工具

@available(macOS 26.0, *)
@MainActor
public final class ExplainFormulaTool: Tool {
    
    public let name = "explainFormula"
    public let description = """
        使用此工具來回報公式解釋結果。
        分析完公式後，調用此工具並提供解釋。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "公式的文字說明")
        public let explanation: String
        
        @Guide(description: "公式中各符號的意義")
        public let symbolMeanings: [String]
        
        @Guide(description: "公式的應用場景")
        public let applications: [String]
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: explainFormula")
        print("   - 符號數: \(arguments.symbolMeanings.count) 個")
        
        return "已完成公式解釋"
    }
    
    public static func createSession(with tool: ExplainFormulaTool) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是數學和科學公式解釋專家。"
                
                """
                解釋規則：
                - 以繁體中文說明
                - 解釋每個符號的意義
                - 提供實際應用場景
                """
                
                "完成後，調用 explainFormula 工具回報結果。"
            }
        )
    }
}

// MARK: - 公式生成工具

@available(macOS 26.0, *)
@MainActor
public final class GenerateFormulaTool: Tool {
    
    public let name = "generateFormula"
    public let description = """
        使用此工具來回報生成的 LaTeX 公式。
        根據描述生成對應的 LaTeX 公式。
        """
    
    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "生成的 LaTeX 公式")
        public let latex: String
        
        @Guide(description: "公式說明")
        public let description: String?
    }
    
    public private(set) var result: Arguments?
    
    public init() {}
    
    public func call(arguments: Arguments) async throws -> String {
        result = arguments
        
        print("🔧 Tool Called: generateFormula")
        print("   - LaTeX: \(arguments.latex)")
        
        return "已生成公式"
    }
    
    public static func createSession(with tool: GenerateFormulaTool) -> LanguageModelSession {
        return LanguageModelSession(
            tools: [tool],
            instructions: Instructions {
                "你是 LaTeX 公式專家。"
                
                "根據用戶描述生成對應的 LaTeX 公式。"
                
                "完成後，調用 generateFormula 工具回報結果。"
            }
        )
    }
}
