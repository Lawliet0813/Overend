//
//  AppleAITest.swift
//  OVEREND
//
//  Apple Intelligence 可用性測試
//

import Foundation
import FoundationModels

@available(macOS 26.0, *)
class AppleAITest {

    /// 測試 Apple Intelligence 是否可用
    static func testAvailability() async -> (available: Bool, message: String) {
        do {
            print("🔍 開始測試 Apple Intelligence...")

            // 嘗試創建 session
            let session = LanguageModelSession()
            print("✅ LanguageModelSession 創建成功")

            // 嘗試一個簡單的請求
            let testPrompt = "請用一句話回覆：你好"
            print("📤 發送測試請求：\(testPrompt)")

            let response = try await session.respond(to: testPrompt)
            print("📥 收到回應：\(response.content)")

            return (true, "✅ Apple Intelligence 可用\n回應：\(response.content)")

        } catch {
            print("❌ Apple Intelligence 測試失敗：\(error)")
            return (false, """
            ❌ Apple Intelligence 不可用

            錯誤：\(error.localizedDescription)

            可能原因：
            1. 系統設定 > Apple Intelligence & Siri 未啟用
            2. 需要登入 Apple ID
            3. 網路連線問題
            4. 區域限制（某些地區不支援）

            技術詳情：\(error)
            """)
        }
    }

    /// 簡易改寫功能（不依賴 AI）
    static func simpleRewrite(text: String, style: String) -> String {
        // 這是一個簡化版本，當 AI 不可用時使用
        switch style {
        case "精簡":
            // 移除多餘空格和換行
            return text
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        case "正式":
            // 將常見口語轉換為正式用語
            var result = text
            let replacements = [
                "很棒": "優秀",
                "很好": "良好",
                "不錯": "合適",
                "我覺得": "本研究認為",
                "我認為": "研究者認為"
            ]
            for (informal, formal) in replacements {
                result = result.replacingOccurrences(of: informal, with: formal)
            }
            return result
        default:
            return text
        }
    }
}
