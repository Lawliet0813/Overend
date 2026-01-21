//
//  AITestFramework.swift
//  OVERENDTests
//
//  AI 測試框架核心
//  提供統一的 AI 功能測試基礎設施
//

import XCTest
@testable import OVEREND

// MARK: - AI 測試框架協議

/// AI 測試用例基礎協議
protocol AITestCase {
    /// 測試用例 ID
    var testID: String { get }
    /// 測試描述
    var description: String { get }
    /// 測試輸入
    var input: Any { get }
    /// 預期輸出
    var expectedOutput: Any? { get }
    /// 驗證邏輯
    func validate(result: Any) -> Bool
}

/// AI 工具測試協議
protocol AIToolTestable {
    /// 工具名稱
    var toolName: String { get }
    /// 執行測試
    func runTests() async throws -> [AITestResult]
}

/// AI 領域測試協議
@MainActor
protocol AIDomainTestable {
    /// 領域名稱
    var domainName: String { get }
    /// 測試所有功能
    func testAllFeatures() async throws -> DomainTestReport
}

// MARK: - 測試結果模型

/// AI 測試結果
struct AITestResult {
    let testID: String
    let testName: String
    let status: TestStatus
    let duration: TimeInterval
    let input: String
    let actualOutput: String?
    let expectedOutput: String?
    let errorMessage: String?
    let metadata: [String: Any]?
    
    enum TestStatus {
        case passed
        case failed
        case skipped
        case error
        
        var emoji: String {
            switch self {
            case .passed: return "✅"
            case .failed: return "❌"
            case .skipped: return "⏭️"
            case .error: return "⚠️"
            }
        }
    }
    
    var isSuccess: Bool {
        status == .passed
    }
}

/// 領域測試報告
struct DomainTestReport {
    let domainName: String
    let totalTests: Int
    let passedTests: Int
    let failedTests: Int
    let skippedTests: Int
    let errorTests: Int
    let duration: TimeInterval
    let results: [AITestResult]
    
    var successRate: Double {
        guard totalTests > 0 else { return 0 }
        return Double(passedTests) / Double(totalTests) * 100
    }
    
    var summary: String {
        """
        📊 領域測試報告: \(domainName)
        ────────────────────────────
        總測試數: \(totalTests)
        通過: \(passedTests) ✅
        失敗: \(failedTests) ❌
        跳過: \(skippedTests) ⏭️
        錯誤: \(errorTests) ⚠️
        成功率: \(String(format: "%.1f", successRate))%
        耗時: \(String(format: "%.2f", duration))s
        """
    }
}

// MARK: - Mock AI 服務

/// 測試用 Mock AI 服務
class MockAIService {
    var shouldSucceed: Bool = true
    var responseDelay: TimeInterval = 0.1
    var mockResponses: [String: String] = [:]
    
    func processRequest(_ request: String, tool: String) async throws -> String {
        // 模擬延遲
        try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw AIServiceError.processingFailed("Mock failure")
        }
        
        // 返回預設或自訂回應
        return mockResponses[tool] ?? "Mock response for \(tool)"
    }
}

// MARK: - 測試資料生成器

/// AI 測試資料生成器
struct AITestDataGenerator {
    
    /// 生成測試 BibTeX 條目
    static func generateBibTeXEntry(key: String = "test2024") -> String {
        """
        @article{\(key),
            author = {Test Author},
            title = {Test Title for AI Processing},
            journal = {Test Journal},
            year = {2024},
            volume = {10},
            pages = {1-20},
            doi = {10.1234/test.2024}
        }
        """
    }
    
    /// 生成測試論文內容
    static func generatePaperContent(language: String = "zh") -> String {
        if language == "zh" {
            return """
            摘要：本研究探討人工智慧在文獻管理中的應用。
            
            1. 引言
            隨著學術文獻數量的快速增長，傳統的文獻管理方法已無法滿足需求。
            
            2. 方法
            本研究採用深度學習技術進行文獻分類和推薦。
            
            3. 結果
            實驗結果顯示，AI 輔助系統可提升 30% 的文獻檢索效率。
            
            4. 結論
            AI 技術在文獻管理領域具有廣闊的應用前景。
            """
        } else {
            return """
            Abstract: This study investigates the application of AI in literature management.
            
            1. Introduction
            With the rapid growth of academic literature, traditional management methods are insufficient.
            
            2. Methods
            This study employs deep learning techniques for literature classification and recommendation.
            
            3. Results
            Experimental results show that AI-assisted systems improve retrieval efficiency by 30%.
            
            4. Conclusion
            AI technology has broad application prospects in literature management.
            """
        }
    }
    
    /// 生成測試 PDF 元資料
    static func generatePDFMetadata() -> [String: Any] {
        [
            "title": "Test Paper Title",
            "authors": ["Author One", "Author Two"],
            "year": 2024,
            "abstract": "This is a test abstract.",
            "keywords": ["AI", "Testing", "Framework"]
        ]
    }
    
    /// 生成測試引用文字
    static func generateCitationText(style: String = "apa") -> String {
        switch style.lowercased() {
        case "apa":
            return "(Smith, 2024)"
        case "mla":
            return "(Smith 123)"
        case "chicago":
            return "(Smith 2024, 123)"
        case "ieee":
            return "[1]"
        default:
            return "(Test, 2024)"
        }
    }
}

// MARK: - 測試斷言輔助

/// AI 測試斷言輔助類
class AITestAssertions {
    
    /// 驗證 AI 回應不為空
    static func assertNotEmpty(_ response: String?, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(response, "AI response should not be nil", file: file, line: line)
        XCTAssertFalse(response?.isEmpty ?? true, "AI response should not be empty", file: file, line: line)
    }
    
    /// 驗證 AI 回應包含關鍵字
    static func assertContains(_ response: String?, keywords: [String], file: StaticString = #file, line: UInt = #line) {
        guard let response = response else {
            XCTFail("Response is nil", file: file, line: line)
            return
        }
        
        for keyword in keywords {
            XCTAssertTrue(response.contains(keyword), 
                         "Response should contain '\(keyword)'", 
                         file: file, line: line)
        }
    }
    
    /// 驗證 JSON 結構
    static func assertValidJSON(_ response: String?, file: StaticString = #file, line: UInt = #line) {
        guard let response = response,
              let data = response.data(using: .utf8) else {
            XCTFail("Invalid response", file: file, line: line)
            return
        }
        
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data), 
                        "Response should be valid JSON", 
                        file: file, line: line)
    }
    
    /// 驗證執行時間
    static func assertExecutionTime<T>(_ block: () async throws -> T, 
                                       maxDuration: TimeInterval,
                                       file: StaticString = #file, 
                                       line: UInt = #line) async rethrows -> T {
        let start = Date()
        let result = try await block()
        let duration = Date().timeIntervalSince(start)
        
        XCTAssertLessThanOrEqual(duration, maxDuration, 
                                "Execution took \(duration)s, expected < \(maxDuration)s",
                                file: file, line: line)
        return result
    }
}

// MARK: - 測試報告生成器

/// AI 測試報告生成器
class AITestReporter {
    
    /// 生成 Markdown 報告
    static func generateMarkdownReport(results: [DomainTestReport], title: String = "AI 測試報告") -> String {
        var markdown = "# \(title)\n\n"
        markdown += "生成時間: \(Date())\n\n"
        markdown += "---\n\n"
        
        // 總體統計
        let totalTests = results.reduce(0) { $0 + $1.totalTests }
        let totalPassed = results.reduce(0) { $0 + $1.passedTests }
        let totalFailed = results.reduce(0) { $0 + $1.failedTests }
        let overallRate = totalTests > 0 ? Double(totalPassed) / Double(totalTests) * 100 : 0
        
        markdown += "## 📊 總體概覽\n\n"
        markdown += "| 指標 | 數值 |\n"
        markdown += "|------|------|\n"
        markdown += "| 測試領域數 | \(results.count) |\n"
        markdown += "| 總測試數 | \(totalTests) |\n"
        markdown += "| 通過 ✅ | \(totalPassed) |\n"
        markdown += "| 失敗 ❌ | \(totalFailed) |\n"
        markdown += "| 成功率 | \(String(format: "%.1f", overallRate))% |\n\n"
        
        // 各領域詳情
        markdown += "## 📋 領域測試詳情\n\n"
        for report in results {
            markdown += "### \(report.domainName)\n\n"
            markdown += report.summary + "\n\n"
            
            if report.failedTests > 0 {
                markdown += "#### ❌ 失敗的測試\n\n"
                for result in report.results where result.status == .failed {
                    markdown += "- **\(result.testName)**: \(result.errorMessage ?? "Unknown error")\n"
                }
                markdown += "\n"
            }
        }
        
        return markdown
    }
    
    /// 生成 JSON 報告
    static func generateJSONReport(results: [DomainTestReport]) throws -> Data {
        let report: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "domains": results.map { domain in
                [
                    "name": domain.domainName,
                    "totalTests": domain.totalTests,
                    "passedTests": domain.passedTests,
                    "failedTests": domain.failedTests,
                    "successRate": domain.successRate,
                    "duration": domain.duration
                ]
            }
        ]
        
        return try JSONSerialization.data(withJSONObject: report, options: .prettyPrinted)
    }
    
    /// 輸出到控制台
    static func printReport(results: [DomainTestReport]) {
        print("\n" + String(repeating: "=", count: 60))
        print("🤖 AI 測試框架執行報告")
        print(String(repeating: "=", count: 60) + "\n")
        
        for report in results {
            print(report.summary)
            print("")
        }
        
        print(String(repeating: "=", count: 60))
    }
}

// MARK: - 測試配置

/// AI 測試配置
struct AITestConfiguration {
    /// 是否啟用真實 AI 服務（false 使用 Mock）
    var useRealAIService: Bool = false
    
    /// 測試超時時間（秒）
    var timeout: TimeInterval = 30
    
    /// 是否生成測試報告
    var generateReport: Bool = true
    
    /// 報告輸出路徑
    var reportOutputPath: String = "./AITestReport.md"
    
    /// 是否啟用詳細日誌
    var verboseLogging: Bool = false
    
    /// 並行測試數量
    var parallelTestCount: Int = 3
    
    /// 失敗時是否立即停止
    var stopOnFailure: Bool = false
}

// MARK: - 測試執行器

/// AI 測試執行器
@MainActor
class AITestRunner {

    private let config: AITestConfiguration
    private var results: [DomainTestReport] = []

    init(config: AITestConfiguration = AITestConfiguration()) {
        self.config = config
    }

    /// 執行所有測試
    func runAllTests(domains: [AIDomainTestable]) async throws {
        print("🚀 開始執行 AI 測試框架...")
        print("配置: \(config.useRealAIService ? "真實 AI" : "Mock AI")")

        let startTime = Date()

        for domain in domains {
            do {
                print("\n📦 測試領域: \(domain.domainName)")
                let report = try await domain.testAllFeatures()
                results.append(report)

                if config.stopOnFailure && report.failedTests > 0 {
                    print("⚠️ 檢測到失敗，停止執行")
                    break
                }
            } catch {
                print("❌ 領域 \(domain.domainName) 測試失敗: \(error)")
                throw error
            }
        }

        let duration = Date().timeIntervalSince(startTime)
        print("\n⏱️ 總耗時: \(String(format: "%.2f", duration))s")

        // 生成報告
        if config.generateReport {
            try generateReports()
        }

        // 輸出到控制台
        AITestReporter.printReport(results: results)
    }
    
    /// 生成測試報告
    private func generateReports() throws {
        let markdown = AITestReporter.generateMarkdownReport(results: results)
        try markdown.write(toFile: config.reportOutputPath, atomically: true, encoding: .utf8)
        print("📄 報告已生成: \(config.reportOutputPath)")
        
        // 同時生成 JSON
        let jsonPath = config.reportOutputPath.replacingOccurrences(of: ".md", with: ".json")
        let jsonData = try AITestReporter.generateJSONReport(results: results)
        try jsonData.write(to: URL(fileURLWithPath: jsonPath))
        print("📄 JSON 報告: \(jsonPath)")
    }
    
    /// 獲取測試結果
    func getResults() -> [DomainTestReport] {
        return results
    }
}
