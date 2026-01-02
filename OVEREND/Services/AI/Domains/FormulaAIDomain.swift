//
//  FormulaAIDomain.swift
//  OVEREND
//
//  公式 AI 領域 - 整合所有公式相關的 AI 功能
//
//  整合來源：
//  - AILatexGenerator
//

import Foundation
import FoundationModels

// MARK: - 公式範例

/// 常用數學公式範例
public struct FormulaExample {
    public let description: String
    public let latex: String
}

// MARK: - 公式 AI 領域

/// 公式 AI 領域
@available(macOS 26.0, *)
@MainActor
public class FormulaAIDomain {
    
    private weak var service: UnifiedAIService?
    
    init(service: UnifiedAIService) {
        self.service = service
    }
    
    // MARK: - 生成 LaTeX 公式
    
    /// 從自然語言描述生成 LaTeX 公式
    /// - Parameter description: 公式的自然語言描述（例如：「畢氏定理」、「二次方程式」）
    /// - Returns: LaTeX 公式字串
    public func generateLatex(from description: String) async throws -> String {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !description.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        let prompt = """
        請將以下數學概念或公式描述轉換為正確的 LaTeX 語法。

        **重要規則：**
        1. 只回傳 LaTeX 公式本身，不要包含 $ 符號
        2. 使用標準 LaTeX 數學語法
        3. 確保語法正確且完整
        4. 如果是複雜公式，使用適當的環境（如 align、cases 等）

        **範例：**
        - 輸入：「畢氏定理」
          輸出：a^2 + b^2 = c^2

        - 輸入：「二次方程式解」
          輸出：x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}

        - 輸入：「高斯積分」
          輸出：\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}

        **現在請轉換：**
        \(description)

        LaTeX 公式：
        """
        
        do {
            let response = try await session.respond(to: prompt)
            let responseText = response.content
            
            // 清理回應
            let cleaned = responseText
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: "```", with: "")
                .replacingOccurrences(of: "latex", with: "")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            return cleaned
        } catch {
            throw AIServiceError.formulaGenerationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 優化 LaTeX 公式
    
    /// 優化或修正現有的 LaTeX 公式
    /// - Parameter latex: 現有的 LaTeX 公式
    /// - Returns: 優化後的 LaTeX 公式
    public func optimizeLatex(_ latex: String) async throws -> String {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !latex.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        let prompt = """
        請檢查並優化以下 LaTeX 公式：

        \(latex)

        請執行以下操作：
        1. 修正語法錯誤
        2. 改善可讀性（適當的空格、換行）
        3. 使用更標準的 LaTeX 慣例
        4. 確保數學符號正確

        只回傳優化後的 LaTeX 公式，不要包含 $ 符號或其他說明。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            let responseText = response.content
            
            return responseText
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                .replacingOccurrences(of: "$", with: "")
        } catch {
            throw AIServiceError.formulaGenerationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 解釋公式
    
    /// 解釋 LaTeX 公式的含義
    /// - Parameter latex: LaTeX 公式
    /// - Returns: 公式解釋
    public func explainFormula(_ latex: String) async throws -> String {
        guard let service = service else {
            throw AIServiceError.notAvailable
        }
        
        try service.ensureAvailable()
        guard !latex.isEmpty else {
            throw AIServiceError.emptyInput
        }
        
        service.startProcessing()
        defer { service.endProcessing() }
        
        let session = service.createSession()
        
        let prompt = """
        請解釋以下 LaTeX 數學公式的含義：

        \(latex)

        請用繁體中文提供：
        1. 公式的名稱（如果有）
        2. 各符號的意義
        3. 公式的用途和應用場景
        
        請簡潔明瞭地回覆。
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw AIServiceError.processingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 常用公式範例
    
    /// 常用數學公式範例
    public static let examples: [FormulaExample] = [
        FormulaExample(description: "畢氏定理", latex: "a^2 + b^2 = c^2"),
        FormulaExample(description: "二次方程式解", latex: "x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}"),
        FormulaExample(description: "歐拉公式", latex: "e^{i\\pi} + 1 = 0"),
        FormulaExample(description: "高斯積分", latex: "\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}"),
        FormulaExample(description: "泰勒級數", latex: "f(x) = \\sum_{n=0}^{\\infty} \\frac{f^{(n)}(a)}{n!}(x-a)^n"),
        FormulaExample(description: "二項式定理", latex: "(x+y)^n = \\sum_{k=0}^{n} \\binom{n}{k} x^{n-k} y^k"),
        FormulaExample(description: "正態分布", latex: "f(x) = \\frac{1}{\\sigma\\sqrt{2\\pi}} e^{-\\frac{(x-\\mu)^2}{2\\sigma^2}}"),
        FormulaExample(description: "麥克勞林級數（e^x）", latex: "e^x = \\sum_{n=0}^{\\infty} \\frac{x^n}{n!}")
    ]
}
