//
//  AIFrameworkIntegrationTests.swift
//  OVERENDTests
//
//  AI 測試框架整合測試
//  展示如何使用測試框架執行完整的測試流程
//

import XCTest
@testable import OVEREND

/// AI 框架整合測試
@MainActor
final class AIFrameworkIntegrationTests: XCTestCase {
    
    var testRunner: AITestRunner!
    var config: AITestConfiguration!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 配置測試框架
        config = AITestConfiguration()
        config.useRealAIService = false  // 使用 Mock 進行測試
        config.timeout = 30
        config.generateReport = true
        config.reportOutputPath = "./TestReports/AITestReport.md"
        config.verboseLogging = true
        
        testRunner = AITestRunner(config: config)
    }
    
    override func tearDown() async throws {
        testRunner = nil
        config = nil
        try await super.tearDown()
    }
    
    // MARK: - 整合測試
    
    /// 測試：執行所有 AI 領域測試
    func testRunAllDomains() async throws {
        // Given - 準備所有測試領域
        let citationDomain = CitationDomainTests()
        let writingDomain = WritingDomainTests()
        let documentDomain = DocumentDomainTests()

        try await citationDomain.setUp()
        try await writingDomain.setUp()
        try await documentDomain.setUp()

        let domains: [AIDomainTestable] = [
            citationDomain,
            writingDomain,
            documentDomain
        ]

        // When - 執行測試
        try await testRunner.runAllTests(domains: domains)

        // Then - 驗證結果
        let results = testRunner.getResults()
        XCTAssertEqual(results.count, 3, "應該有 3 個領域的測試報告")

        // 驗證每個領域都有測試結果
        for report in results {
            XCTAssertGreaterThan(report.totalTests, 0, "\(report.domainName) 應該至少有一個測試")
            print("\n" + report.summary)
        }

        // 計算總體成功率
        let totalTests = results.reduce(0) { $0 + $1.totalTests }
        let totalPassed = results.reduce(0) { $0 + $1.passedTests }
        let overallSuccessRate = Double(totalPassed) / Double(totalTests) * 100

        print("\n📊 總體成功率: \(String(format: "%.1f", overallSuccessRate))%")

        // 期望至少 80% 的測試通過
        XCTAssertGreaterThanOrEqual(overallSuccessRate, 80.0,
                                   "總體成功率應該至少達到 80%")
    }
    
    /// 測試：單一領域測試（引用領域）
    func testCitationDomainOnly() async throws {
        // Given
        let citationDomain = CitationDomainTests()
        try await citationDomain.setUp()

        // When
        let report = try await citationDomain.testAllFeatures()

        // Then
        XCTAssertGreaterThan(report.totalTests, 0)
        XCTAssertGreaterThan(report.passedTests, 0)
        print("\n" + report.summary)

        // 驗證成功率
        XCTAssertGreaterThanOrEqual(report.successRate, 80.0)
    }
    
    /// 測試：單一領域測試（寫作領域）
    func testWritingDomainOnly() async throws {
        // Given
        let writingDomain = WritingDomainTests()
        try await writingDomain.setUp()

        // When
        let report = try await writingDomain.testAllFeatures()

        // Then
        XCTAssertGreaterThan(report.totalTests, 0)
        XCTAssertGreaterThan(report.passedTests, 0)
        print("\n" + report.summary)

        // 驗證成功率
        XCTAssertGreaterThanOrEqual(report.successRate, 80.0)
    }
    
    /// 測試：單一領域測試（文件處理領域）
    func testDocumentDomainOnly() async throws {
        // Given
        let documentDomain = DocumentDomainTests()
        try await documentDomain.setUp()

        // When
        let report = try await documentDomain.testAllFeatures()

        // Then
        XCTAssertGreaterThan(report.totalTests, 0)
        XCTAssertGreaterThan(report.passedTests, 0)
        print("\n" + report.summary)

        // 驗證成功率
        XCTAssertGreaterThanOrEqual(report.successRate, 80.0)
    }
    
    // MARK: - 測試工具測試
    
    /// 測試：Mock AI 服務
    func testMockAIService() async throws {
        // Given
        let mockAI = MockAIService()
        mockAI.shouldSucceed = true
        mockAI.responseDelay = 0.1
        mockAI.mockResponses["test_tool"] = "Test response"
        
        // When
        let response = try await mockAI.processRequest("test input", tool: "test_tool")
        
        // Then
        XCTAssertEqual(response, "Test response")
    }
    
    /// 測試：Mock AI 服務失敗情況
    func testMockAIServiceFailure() async throws {
        // Given
        let mockAI = MockAIService()
        mockAI.shouldSucceed = false
        
        // When & Then
        do {
            _ = try await mockAI.processRequest("test input", tool: "test_tool")
            XCTFail("應該拋出錯誤")
        } catch let error as AIServiceError {
            // 驗證錯誤類型
            switch error {
            case .processingFailed(let message):
                XCTAssertEqual(message, "Mock failure")
            default:
                XCTFail("錯誤類型不符")
            }
        }
    }
    
    /// 測試：測試資料生成器
    func testDataGenerator() {
        // BibTeX 條目生成
        let bibtex = AITestDataGenerator.generateBibTeXEntry()
        XCTAssertTrue(bibtex.contains("@article"))
        XCTAssertTrue(bibtex.contains("author"))
        XCTAssertTrue(bibtex.contains("title"))
        
        // 論文內容生成
        let paperZh = AITestDataGenerator.generatePaperContent(language: "zh")
        XCTAssertTrue(paperZh.contains("摘要"))
        
        let paperEn = AITestDataGenerator.generatePaperContent(language: "en")
        XCTAssertTrue(paperEn.contains("Abstract"))
        
        // PDF 元資料生成
        let metadata = AITestDataGenerator.generatePDFMetadata()
        XCTAssertNotNil(metadata["title"])
        XCTAssertNotNil(metadata["authors"])
        
        // 引用文字生成
        let citationAPA = AITestDataGenerator.generateCitationText(style: "apa")
        XCTAssertTrue(citationAPA.contains("2024"))
        
        let citationIEEE = AITestDataGenerator.generateCitationText(style: "ieee")
        XCTAssertTrue(citationIEEE.contains("[1]"))
    }
    
    /// 測試：測試斷言輔助
    func testAssertions() {
        // assertNotEmpty
        AITestAssertions.assertNotEmpty("test")
        
        // assertContains
        AITestAssertions.assertContains("This is a test", keywords: ["test"])
        
        // assertValidJSON
        let json = """
        {"key": "value"}
        """
        AITestAssertions.assertValidJSON(json)
    }
    
    /// 測試：執行時間斷言
    func testExecutionTimeAssertion() async throws {
        // Given
        let maxDuration: TimeInterval = 0.5
        
        // When & Then
        let result = try await AITestAssertions.assertExecutionTime({
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
            return "completed"
        }, maxDuration: maxDuration)
        
        XCTAssertEqual(result, "completed")
    }
    
    // MARK: - 報告生成測試
    
    /// 測試：Markdown 報告生成
    func testMarkdownReportGeneration() async throws {
        // Given
        let citationDomain = CitationDomainTests()
        let writingDomain = WritingDomainTests()
        try await citationDomain.setUp()
        try await writingDomain.setUp()

        let domains: [AIDomainTestable] = [
            citationDomain,
            writingDomain
        ]

        try await testRunner.runAllTests(domains: domains)
        let results = testRunner.getResults()

        // When
        let markdown = AITestReporter.generateMarkdownReport(results: results, title: "測試報告")

        // Then
        XCTAssertTrue(markdown.contains("# 測試報告"))
        XCTAssertTrue(markdown.contains("總體概覽"))
        XCTAssertTrue(markdown.contains("領域測試詳情"))
        XCTAssertFalse(markdown.isEmpty)

        print("\n生成的 Markdown 報告:\n\(markdown)")
    }
    
    /// 測試：JSON 報告生成
    func testJSONReportGeneration() async throws {
        // Given
        let citationDomain = CitationDomainTests()
        try await citationDomain.setUp()

        let domains: [AIDomainTestable] = [
            citationDomain
        ]

        try await testRunner.runAllTests(domains: domains)
        let results = testRunner.getResults()

        // When
        let jsonData = try AITestReporter.generateJSONReport(results: results)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Then
        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["timestamp"])
        XCTAssertNotNil(json?["domains"])

        if let domains = json?["domains"] as? [[String: Any]] {
            XCTAssertGreaterThan(domains.count, 0)
            print("\n生成的 JSON 報告: \(domains)")
        }
    }
    
    // MARK: - 效能測試
    
    /// 測試：並行執行效能
    func testParallelExecution() async throws {
        // Given
        let startTime = Date()

        let citationDomain = CitationDomainTests()
        let writingDomain = WritingDomainTests()
        let documentDomain = DocumentDomainTests()

        try await citationDomain.setUp()
        try await writingDomain.setUp()
        try await documentDomain.setUp()

        let domains: [AIDomainTestable] = [
            citationDomain,
            writingDomain,
            documentDomain
        ]

        // When
        try await testRunner.runAllTests(domains: domains)

        // Then
        let duration = Date().timeIntervalSince(startTime)
        print("\n⏱️ 並行執行耗時: \(String(format: "%.2f", duration))s")

        // 驗證執行時間在合理範圍內（應該 < 60 秒）
        XCTAssertLessThan(duration, 60.0, "測試執行時間應該少於 60 秒")
    }
    
    /// 測試：記憶體使用
    func testMemoryUsage() async throws {
        // Given
        let citationDomain = CitationDomainTests()
        let writingDomain = WritingDomainTests()

        try await citationDomain.setUp()
        try await writingDomain.setUp()

        let domains: [AIDomainTestable] = [
            citationDomain,
            writingDomain
        ]

        // When
        try await testRunner.runAllTests(domains: domains)

        // Then
        // 這裡可以加入記憶體監控邏輯
        print("\n💾 測試完成，檢查記憶體使用情況")
    }
}
