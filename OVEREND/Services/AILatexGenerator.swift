//
//  AILatexGenerator.swift
//  OVEREND
//
//  AI 驅動的 LaTeX 公式生成器 - 將自然語言轉換為 LaTeX
//

import Foundation
import FoundationModels

/// AI LaTeX 公式生成器
class AILatexGenerator {

    /// 使用 Apple Intelligence 將自然語言轉換為 LaTeX 公式
    /// - Parameter description: 公式的自然語言描述（例如：「畢氏定理」、「二次方程式」）
    /// - Returns: LaTeX 公式字串
    static func generateFormula(from description: String) async throws -> String {
        // 檢查是否可用 Apple Intelligence
        guard AppleAIService.shared.isAvailable else {
            throw NSError(domain: "AILatexGenerator", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Apple Intelligence 不可用。請確保系統支援並已啟用。"
            ])
        }

        // 建構 AI 提示詞
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

        // 呼叫 Apple AI
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        let responseText = response.content

        // 清理回應（移除可能的 $ 符號、換行等）
        let cleaned = responseText
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "latex", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        return cleaned
    }

    /// 使用 AI 優化或修正現有的 LaTeX 公式
    /// - Parameter latex: 現有的 LaTeX 公式
    /// - Returns: 優化後的 LaTeX 公式
    static func optimizeFormula(_ latex: String) async throws -> String {
        guard AppleAIService.shared.isAvailable else {
            throw NSError(domain: "AILatexGenerator", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Apple Intelligence 不可用"
            ])
        }

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

        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        let responseText = response.content

        return responseText
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
    }

    /// 常用數學公式範例
    static let examples: [(description: String, latex: String)] = [
        ("畢氏定理", "a^2 + b^2 = c^2"),
        ("二次方程式解", "x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}"),
        ("歐拉公式", "e^{i\\pi} + 1 = 0"),
        ("高斯積分", "\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}"),
        ("泰勒級數", "f(x) = \\sum_{n=0}^{\\infty} \\frac{f^{(n)}(a)}{n!}(x-a)^n"),
        ("二項式定理", "(x+y)^n = \\sum_{k=0}^{n} \\binom{n}{k} x^{n-k} y^k"),
        ("柯西不等式", "\\left(\\sum_{i=1}^{n} a_i b_i\\right)^2 \\leq \\left(\\sum_{i=1}^{n} a_i^2\\right)\\left(\\sum_{i=1}^{n} b_i^2\\right)"),
        ("正態分布", "f(x) = \\frac{1}{\\sigma\\sqrt{2\\pi}} e^{-\\frac{(x-\\mu)^2}{2\\sigma^2}}"),
        ("矩陣行列式（2x2）", "\\begin{vmatrix} a & b \\\\ c & d \\end{vmatrix} = ad - bc"),
        ("麥克勞林級數（e^x）", "e^x = \\sum_{n=0}^{\\infty} \\frac{x^n}{n!}")
    ]
}
