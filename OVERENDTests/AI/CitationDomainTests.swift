//
//  CitationDomainTests.swift
//  OVERENDTests
//
//  引用領域測試套件
//  測試所有引用相關的 AI 功能
//

import XCTest
@testable import OVEREND

/// 引用領域測試
@MainActor
class CitationDomainTests: XCTestCase, AIDomainTestable {
    
    var domainName: String { "Citation Domain" }
    
    private var mockAI: MockAIService!
    private var testResults: [AITestResult] = []
    
    override func setUp() async throws {
        try await super.setUp()
        mockAI = MockAIService()
        testResults = []
        
        // 設定 Mock 回應
        mockAI.mockResponses = [
            "format_citation": """
            {
                "formatted": "(Smith, 2024)",
                "style": "apa",
                "success": true
            }
            """,
            "generate_bibliography": """
            Smith, J. (2024). Test Article. Journal of Testing, 10(1), 1-20.
            """,
            "validate_citation": """
            {
                "valid": true,
                "issues": []
            }
            """
        ]
    }
    
    // MARK: - 主要測試方法
    
    func testAllFeatures() async throws -> DomainTestReport {
        let startTime = Date()

        // 執行所有測試
        try await testFormatCitation()
        try await testGenerateBibliography()
        try await testValidateCitation()
        try await testMultipleCitationStyles()
        try await testInTextCitation()

        let duration = Date().timeIntervalSince(startTime)

        // 統計結果
        let passed = testResults.filter { $0.status == .passed }.count
        let failed = testResults.filter { $0.status == .failed }.count
        let skipped = testResults.filter { $0.status == .skipped }.count
        let errors = testResults.filter { $0.status == .error }.count

        return DomainTestReport(
            domainName: domainName,
            totalTests: testResults.count,
            passedTests: passed,
            failedTests: failed,
            skippedTests: skipped,
            errorTests: errors,
            duration: duration,
            results: testResults
        )
    }
    
    // MARK: - 個別測試用例
    
    /// 測試：格式化引用
    func testFormatCitation() async throws {
        let testID = "citation_001"
        let startTime = Date()
        
        do {
            let input = AITestDataGenerator.generateBibTeXEntry()
            let response = try await mockAI.processRequest(input, tool: "format_citation")
            
            AITestAssertions.assertNotEmpty(response)
            AITestAssertions.assertValidJSON(response)
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "格式化引用 (APA)",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: input,
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: ["style": "apa"]
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "格式化引用 (APA)",
                status: .failed,
                duration: Date().timeIntervalSince(startTime),
                input: "",
                actualOutput: nil,
                expectedOutput: nil,
                errorMessage: error.localizedDescription,
                metadata: nil
            ))
        }
    }
    
    /// 測試：生成參考文獻列表
    func testGenerateBibliography() async throws {
        let testID = "citation_002"
        let startTime = Date()
        
        do {
            let input = AITestDataGenerator.generateBibTeXEntry()
            let response = try await mockAI.processRequest(input, tool: "generate_bibliography")
            
            AITestAssertions.assertNotEmpty(response)
            AITestAssertions.assertContains(response, keywords: ["Smith", "2024"])
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "生成參考文獻列表",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: input,
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: nil
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "生成參考文獻列表",
                status: .failed,
                duration: Date().timeIntervalSince(startTime),
                input: "",
                actualOutput: nil,
                expectedOutput: nil,
                errorMessage: error.localizedDescription,
                metadata: nil
            ))
        }
    }
    
    /// 測試：驗證引用格式
    func testValidateCitation() async throws {
        let testID = "citation_003"
        let startTime = Date()
        
        do {
            let input = AITestDataGenerator.generateCitationText()
            let response = try await mockAI.processRequest(input, tool: "validate_citation")
            
            AITestAssertions.assertNotEmpty(response)
            AITestAssertions.assertValidJSON(response)
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "驗證引用格式",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: input,
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: nil
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "驗證引用格式",
                status: .failed,
                duration: Date().timeIntervalSince(startTime),
                input: "",
                actualOutput: nil,
                expectedOutput: nil,
                errorMessage: error.localizedDescription,
                metadata: nil
            ))
        }
    }
    
    /// 測試：多種引用風格
    func testMultipleCitationStyles() async throws {
        let styles = ["apa", "mla", "chicago", "ieee"]
        
        for style in styles {
            let testID = "citation_style_\(style)"
            let startTime = Date()
            
            do {
                let input = AITestDataGenerator.generateBibTeXEntry()
                mockAI.mockResponses["format_citation"] = """
                {
                    "formatted": "\(AITestDataGenerator.generateCitationText(style: style))",
                    "style": "\(style)",
                    "success": true
                }
                """
                
                let response = try await mockAI.processRequest(input, tool: "format_citation")
                AITestAssertions.assertNotEmpty(response)
                
                testResults.append(AITestResult(
                    testID: testID,
                    testName: "引用風格: \(style.uppercased())",
                    status: .passed,
                    duration: Date().timeIntervalSince(startTime),
                    input: input,
                    actualOutput: response,
                    expectedOutput: nil,
                    errorMessage: nil,
                    metadata: ["style": style]
                ))
            } catch {
                testResults.append(AITestResult(
                    testID: testID,
                    testName: "引用風格: \(style.uppercased())",
                    status: .failed,
                    duration: Date().timeIntervalSince(startTime),
                    input: "",
                    actualOutput: nil,
                    expectedOutput: nil,
                    errorMessage: error.localizedDescription,
                    metadata: ["style": style]
                ))
            }
        }
    }
    
    /// 測試：文內引用
    func testInTextCitation() async throws {
        let testID = "citation_005"
        let startTime = Date()
        
        do {
            let input = "Recent studies show significant results"
            mockAI.mockResponses["insert_citation"] = """
            Recent studies show significant results (Smith, 2024)
            """
            
            let response = try await mockAI.processRequest(input, tool: "insert_citation")
            AITestAssertions.assertNotEmpty(response)
            AITestAssertions.assertContains(response, keywords: ["Smith", "2024"])
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "插入文內引用",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: input,
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: nil
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "插入文內引用",
                status: .failed,
                duration: Date().timeIntervalSince(startTime),
                input: "",
                actualOutput: nil,
                expectedOutput: nil,
                errorMessage: error.localizedDescription,
                metadata: nil
            ))
        }
    }
}
