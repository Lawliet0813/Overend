//
//  DocumentDomainTests.swift
//  OVERENDTests
//
//  文件處理領域測試套件
//  測試所有文件處理相關的 AI 功能
//

import XCTest
@testable import OVEREND

/// 文件處理領域測試
@MainActor
class DocumentDomainTests: XCTestCase, AIDomainTestable {
    
    var domainName: String { "Document Domain" }
    
    private var mockAI: MockAIService!
    private var testResults: [AITestResult] = []
    
    override func setUp() async throws {
        try await super.setUp()
        mockAI = MockAIService()
        testResults = []
        
        // 設定 Mock 回應
        mockAI.mockResponses = [
            "extract_metadata": """
            {
                "title": "Test Paper Title",
                "authors": ["Author One", "Author Two"],
                "year": 2024,
                "abstract": "This is a test abstract.",
                "keywords": ["AI", "Testing"]
            }
            """,
            "summarize_document": "本文探討了AI測試框架的設計與實現，提出了一套完整的測試方法論。",
            "classify_document": """
            {
                "category": "Computer Science",
                "subcategory": "Artificial Intelligence",
                "confidence": 0.95
            }
            """,
            "extract_sections": """
            {
                "sections": [
                    {"title": "Abstract", "start": 0, "end": 150},
                    {"title": "Introduction", "start": 151, "end": 500},
                    {"title": "Methods", "start": 501, "end": 1000}
                ]
            }
            """
        ]
    }
    
    // MARK: - 主要測試方法
    
    func testAllFeatures() async throws -> DomainTestReport {
        let startTime = Date()

        // 執行所有測試
        try await testExtractMetadata()
        try await testSummarizeDocument()
        try await testClassifyDocument()
        try await testExtractSections()
        try await testCompareDocuments()

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
    
    /// 測試：提取文件元資料
    func testExtractMetadata() async throws {
        let testID = "document_001"
        let startTime = Date()
        
        do {
            let input = AITestDataGenerator.generatePaperContent(language: "en")
            let response = try await mockAI.processRequest(input, tool: "extract_metadata")
            
            AITestAssertions.assertNotEmpty(response)
            AITestAssertions.assertValidJSON(response)
            AITestAssertions.assertContains(response, keywords: ["title", "authors"])
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "提取文件元資料",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: input.prefix(100) + "...",
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: nil
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "提取文件元資料",
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
    
    /// 測試：文件摘要
    func testSummarizeDocument() async throws {
        let testID = "document_002"
        let startTime = Date()
        
        do {
            let input = AITestDataGenerator.generatePaperContent()
            let response = try await mockAI.processRequest(input, tool: "summarize_document")
            
            AITestAssertions.assertNotEmpty(response)
            XCTAssertLessThan(response.count, input.count / 2, "摘要應該明顯短於原文")
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "生成文件摘要",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: input.prefix(100) + "...",
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: ["compression_ratio": Double(response.count) / Double(input.count)]
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "生成文件摘要",
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
    
    /// 測試：文件分類
    func testClassifyDocument() async throws {
        let testID = "document_003"
        let startTime = Date()
        
        do {
            let input = AITestDataGenerator.generatePaperContent()
            let response = try await mockAI.processRequest(input, tool: "classify_document")
            
            AITestAssertions.assertNotEmpty(response)
            AITestAssertions.assertValidJSON(response)
            AITestAssertions.assertContains(response, keywords: ["category", "confidence"])
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "文件分類",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: input.prefix(100) + "...",
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: nil
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "文件分類",
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
    
    /// 測試：提取文件章節
    func testExtractSections() async throws {
        let testID = "document_004"
        let startTime = Date()
        
        do {
            let input = AITestDataGenerator.generatePaperContent()
            let response = try await mockAI.processRequest(input, tool: "extract_sections")
            
            AITestAssertions.assertNotEmpty(response)
            AITestAssertions.assertValidJSON(response)
            AITestAssertions.assertContains(response, keywords: ["sections"])
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "提取文件章節結構",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: input.prefix(100) + "...",
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: nil
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "提取文件章節結構",
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
    
    /// 測試：比較文件
    func testCompareDocuments() async throws {
        let testID = "document_005"
        let startTime = Date()
        
        do {
            let input1 = AITestDataGenerator.generatePaperContent()
            let input2 = AITestDataGenerator.generatePaperContent(language: "en")
            let combinedInput = "Document 1:\n\(input1)\n\nDocument 2:\n\(input2)"
            
            mockAI.mockResponses["compare_documents"] = """
            {
                "similarity": 0.75,
                "common_topics": ["AI", "research", "methodology"],
                "differences": ["語言不同", "研究焦點略有差異"]
            }
            """
            
            let response = try await mockAI.processRequest(combinedInput, tool: "compare_documents")
            
            AITestAssertions.assertNotEmpty(response)
            AITestAssertions.assertValidJSON(response)
            AITestAssertions.assertContains(response, keywords: ["similarity"])
            
            testResults.append(AITestResult(
                testID: testID,
                testName: "比較兩份文件",
                status: .passed,
                duration: Date().timeIntervalSince(startTime),
                input: "Two documents comparison",
                actualOutput: response,
                expectedOutput: nil,
                errorMessage: nil,
                metadata: nil
            ))
        } catch {
            testResults.append(AITestResult(
                testID: testID,
                testName: "比較兩份文件",
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
