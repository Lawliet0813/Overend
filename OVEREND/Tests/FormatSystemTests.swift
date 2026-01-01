//
//  FormatSystemTests.swift
//  OVEREND
//
//  格式系統測試
//

import Foundation
import AppKit

/// 格式系統測試
class FormatSystemTests {
    
    // MARK: - 範本系統測試
    
    static func testTemplateManager() {
        print("=== 測試範本管理器 ===\n")
        
        let manager = TemplateManager.shared
        
        // 1. 測試載入預設範本
        print("1. 載入政大範本...")
        let nccuTemplate = manager.load("政大論文格式")
        print("   ✅ 範本名稱：\(nccuTemplate.name)")
        print("   ✅ 版本：\(nccuTemplate.version)")
        print("   ✅ 頁面大小：\(nccuTemplate.pageSetup.paperSize)")
        print("   ✅ 上邊距：\(nccuTemplate.pageSetup.margin.top)pt\n")
        
        // 2. 測試列出所有範本
        print("2. 列出所有範本...")
        let templates = manager.allTemplates()
        print("   ✅ 共 \(templates.count) 個範本")
        for template in templates {
            print("      - \(template.name)")
        }
        print()
    }
    
    // MARK: - CSS 生成測試
    
    static func testCSSGeneration() {
        print("=== 測試 CSS 生成 ===\n")
        
        let template = FormatTemplate.nccu
        let css = DocumentFormatter.generateCSS(from: template)
        
        print("生成的 CSS 前 500 字元：")
        print(String(css.prefix(500)))
        print("...\n")
        
        // 驗證關鍵樣式存在
        assert(css.contains("font-family"), "❌ CSS 應包含字體定義")
        assert(css.contains("font-size"), "❌ CSS 應包含字體大小")
        assert(css.contains("@page"), "❌ CSS 應包含頁面設定")
        
        print("✅ CSS 生成測試通過\n")
    }
    
    // MARK: - HTML 轉換測試
    
    static func testHTMLConversion() {
        print("=== 測試 HTML 轉換 ===\n")
        
        // 建立測試用 NSAttributedString
        let testString = NSMutableAttributedString()
        
        // 標題
        let titleFont = NSFont.boldSystemFont(ofSize: 18)
        let titleAttr = [NSAttributedString.Key.font: titleFont]
        testString.append(NSAttributedString(string: "第一章 緒論\n", attributes: titleAttr))
        
        // 內容
        let bodyFont = NSFont.systemFont(ofSize: 12)
        let bodyAttr = [NSAttributedString.Key.font: bodyFont]
        testString.append(NSAttributedString(string: "這是測試內容。\n", attributes: bodyAttr))
        
        // 轉換成 HTML
        let template = FormatTemplate.nccu
        let html = DocumentFormatter.toHTML(testString, template: template)
        
        print("生成的 HTML 長度：\(html.count) 字元")
        print("HTML 前 800 字元：")
        print(String(html.prefix(800)))
        print("...\n")
        
        // 驗證
        assert(html.contains("<!DOCTYPE html>"), "❌ 應包含 DOCTYPE")
        assert(html.contains("<h1"), "❌ 應包含 h1 標籤")
        assert(html.contains("第一章"), "❌ 應包含標題內容")
        assert(html.contains("<style>"), "❌ 應包含 style 標籤")
        
        print("✅ HTML 轉換測試通過\n")
        
        // 測試反向轉換
        print("測試 HTML → NSAttributedString...")
        let converted = DocumentFormatter.fromHTML(html, template: template)
        print("   ✅ 轉換後字數：\(converted.length)")
        print("   ✅ 內容包含：\(converted.string.prefix(20))...\n")
    }
    
    // MARK: - 完整流程測試
    
    static func testCompleteWorkflow() {
        print("=== 測試完整工作流程 ===\n")
        
        print("1. 建立文件...")
        let testContent = """
        第一章 緒論
        
        第一節 研究動機
        
        本研究探討台灣公共行政的相關議題。
        
        第二節 研究目的
        
        （一）分析現況
        （二）提出建議
        
        參考文獻
        
        王道還（2004）。科學的文化意義。台北：巨流。
        """
        
        let attributedString = NSAttributedString(string: testContent)
        print("   ✅ 文件建立完成\n")
        
        print("2. 載入範本...")
        let template = TemplateManager.shared.load("政大論文格式")
        print("   ✅ 範本：\(template.name)\n")
        
        print("3. 轉換成 HTML...")
        let html = DocumentFormatter.toHTML(attributedString, template: template)
        print("   ✅ HTML 長度：\(html.count) 字元\n")
        
        print("4. 驗證 CSS 包含政大格式...")
        assert(html.contains("font-family: 標楷體"), "❌ 應使用標楷體")
        assert(html.contains("font-size: 18pt"), "❌ 第一章應為 18pt")
        assert(html.contains("font-size: 16pt"), "❌ 第一節應為 16pt")
        print("   ✅ CSS 格式正確\n")
        
        print("5. 轉換回 NSAttributedString...")
        let converted = DocumentFormatter.fromHTML(html, template: template)
        print("   ✅ 轉換完成，字數：\(converted.length)\n")
        
        print("✅ 完整工作流程測試通過\n")
    }
    
    // MARK: - 執行所有測試
    
    static func runAll() {
        print("\n")
        print("╔════════════════════════════════════════╗")
        print("║   OVEREND 格式系統測試                 ║")
        print("╚════════════════════════════════════════╝")
        print("\n")
        
        testTemplateManager()
        testCSSGeneration()
        testHTMLConversion()
        testCompleteWorkflow()
        
        print("╔════════════════════════════════════════╗")
        print("║   所有測試完成！                       ║")
        print("╚════════════════════════════════════════╝")
        print("\n")
    }
}
