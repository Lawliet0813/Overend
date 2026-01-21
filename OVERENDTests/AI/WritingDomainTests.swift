//
//  WritingDomainTests.swift
//  OVERENDTests
//
//  寫作領域測試套件
//  測試所有寫作輔助相關的 AI 功能
//

import XCTest
@testable import OVEREND

/// 寫作領域測試
@MainActor
class WritingDomainTests: XCTestCase, AIDomainTestable {
    
    var domainName: String { "Writing Domain" }
    
    private var mockAI: MockAIService!
    private var testResults: [AITestResult] = []
    
    override func setUp() async throws {
        try await super.setUp()
        mockAI = MockAIService()
        testResults = []
        
        // 設定 Mock 回應
        mockAI.mockResponses = [
            "improve_writing": "這是改善後的學術寫作內容，更加精確和專業。",
            "check_grammar": """
            {
                "corrections": [
                    {"type": "grammar", "original": "is", "suggestion": "are", "position": 10}
                ],
                "score": 95
            }
            """,
            "generate_abstract": "本研究探討了人工智慧在學術研究中的應用，結果顯示AI技術可以有效提升研究效率。",
            "paraphrase": "研究表明，人工智慧技術在提升學術生產力方面具有顯著效果。",
            "expand_content": """
            此外，研究還發現AI技術在文獻檢索、資料分析和論文撰寫等多個環節都能提供有效支援。
            這些功能的整合使用可以大幅縮短研究週期，提高研究品質。
            """
        ]
    }
    
    // MARK: - 主要測試方法
    
    func testAllFeatures() async throws -> DomainTestReport {
        let startTime = Date()

        // 執行所有測試
        try await testImproveWriting()
        try await testCheckGrammar()
        try await testGenerateAbstract()
        try await testParaphrase()
        try await testExpandContent()
        try await testWritingStyleConsistency()

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
    
    /// 測試：改善寫作
    func testImproveWriting() async throws {
        let testID = "writing_001"
        let startTime = Date()
        
        do {
            let input = "這個研究很重要"
            let response = try await mockAI.processRequest(input, tool: "improve_writing")
            
            AITestAssertions.assertNotEmpty(response)
            XCTAssertGreaterThan(response.count, input.count, "改善後的內容應該更詳細")
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "改善學術寫作",
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
                testName: "改善學術寫作",
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
    
    /// 測試：文法檢查
    func testCheckGrammar() async throws {
        let testID = "writing_002"
        let startTime = Date()
        
        do {
            let input = "The results is significant"
            let response = try await mockAI.processRequest(input, tool: "check_grammar")
            
            AITestAssertions.assertNotEmpty(response)
            AITestAssertions.assertValidJSON(response)
            AITestAssertions.assertContains(response, keywords: ["corrections"])
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "文法檢查",
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
                testName: "文法檢查",
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
    
    /// 測試：生成摘要
    func testGenerateAbstract() async throws {
        let testID = "writing_003"
        let startTime = Date()
        
        do {
            let input = AITestDataGenerator.generatePaperContent()
            let response = try await mockAI.processRequest(input, tool: "generate_abstract")
            
            AITestAssertions.assertNotEmpty(response)
            XCTAssertLessThan(response.count, input.count, "摘要應該比全文短")
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "生成論文摘要",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: input.prefix(100) + "...",
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: ["input_length": input.count, "output_length": response.count]
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "生成論文摘要",
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
    
    /// 測試：改寫內容
    func testParaphrase() async throws {
        let testID = "writing_004"
        let startTime = Date()
        
        do {
            let input = "人工智慧技術可以提升學術生產力"
            let response = try await mockAI.processRequest(input, tool: "paraphrase")
            
            AITestAssertions.assertNotEmpty(response)
            XCTAssertNotEqual(response, input, "改寫後的內容應該與原文不同")
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "改寫內容",
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
                testName: "改寫內容",
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
    
    /// 測試：擴展內容
    func testExpandContent() async throws {
        let testID = "writing_005"
        let startTime = Date()
        
        do {
            let input = "AI 技術很有用"
            let response = try await mockAI.processRequest(input, tool: "expand_content")
            
            AITestAssertions.assertNotEmpty(response)
            XCTAssertGreaterThan(response.count, input.count * 2, "擴展後的內容應該更詳細")
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "擴展內容",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: input,
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: ["expansion_ratio": Double(response.count) / Double(input.count)]
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "擴展內容",
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
    
    /// 測試：寫作風格一致性
    func testWritingStyleConsistency() async throws {
        let testID = "writing_006"
        let startTime = Date()
        
        do {
            let input = "這篇論文包含多個章節，風格可能不一致"
            mockAI.mockResponses["check_style"] = """
            {
                "consistency_score": 85,
                "issues": [
                    {"section": "引言", "issue": "使用第一人稱"},
                    {"section": "結論", "issue": "語氣較口語化"}
                ]
            }
            """
            
            let response = try await mockAI.processRequest(input, tool: "check_style")
            
            AITestAssertions.assertNotEmpty(response)
            AITestAssertions.assertValidJSON(response)
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "檢查寫作風格一致性",
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
                testName: "檢查寫作風格一致性",
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
