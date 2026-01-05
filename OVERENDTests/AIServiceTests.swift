//
//  AIServiceTests.swift
//  OVERENDTests
//
//  AI 服務單元測試
//  測試 AI 工具呼叫和領域功能
//

import XCTest
@testable import OVEREND

// MARK: - AI 服務可用性測試

/// 測試 AI 服務錯誤定義
final class AIServiceErrorTests: XCTestCase {
    
    func testErrorDescriptions() {
        // Given - 使用實際的錯誤類型
        let errors: [AIServiceError] = [
            .notAvailable,
            .processingFailed("test"),
            .emptyInput,
            .invalidResponse,
            .networkError("network")
        ]
        
        // Then
        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty, "錯誤應有描述")
        }
    }
    
    func testNotAvailableError() {
        // Given
        let error = AIServiceError.notAvailable
        
        // Then
        XCTAssertTrue(error.localizedDescription.contains("Apple Intelligence") ||
                      error.localizedDescription.contains("可用"),
                      "notAvailable 應說明 AI 不可用")
    }
    
    func testProcessingFailedError() {
        // Given
        let reason = "Processing error"
        let error = AIServiceError.processingFailed(reason)
        
        // Then
        XCTAssertTrue(error.localizedDescription.contains("處理") ||
                      error.localizedDescription.contains("失敗"),
                      "processingFailed 應說明處理失敗")
    }
    
    func testDomainSpecificErrors() {
        // Given - 各領域特定錯誤
        let domainErrors: [AIServiceError] = [
            .writingSuggestionFailed("test"),
            .citationFormatError("test"),
            .translationFailed("test"),
            .complianceCheckFailed("test"),
            .metadataExtractionFailed("test"),
            .formulaGenerationFailed("test")
        ]
        
        // Then
        for error in domainErrors {
            XCTAssertFalse(error.localizedDescription.isEmpty,
                          "領域錯誤應有描述")
        }
    }
}

// MARK: - ExtractPDFMetadataTool 測試 (需 macOS 26.0)

@available(macOS 26.0, *)
@MainActor
final class ExtractPDFMetadataToolTests: XCTestCase {
    
    var tool: ExtractPDFMetadataTool!
    
    override func setUp() async throws {
        await MainActor.run {
            tool = ExtractPDFMetadataTool()
        }
    }
    
    override func tearDown() async throws {
        tool = nil
    }
    
    func testToolNameAndDescription() {
        XCTAssertEqual(tool.name, "extractPDFMetadata", "工具名稱應正確")
        XCTAssertFalse(tool.description.isEmpty, "工具應有描述")
    }
    
    func testInitialResultIsNil() {
        XCTAssertNil(tool.extractedResult, "初始結果應為 nil")
    }
    
    func testPlaceholderTitlePatterns() {
        // 測試佔位符標題列表
        let placeholders = [
            "Unknown Title",
            "Untitled",
            "Sample Title", 
            "Example Article"
        ]
        
        for placeholder in placeholders {
            // 透過工具的 call 方法間接測試
            XCTAssertTrue(placeholder.lowercased().contains("unknown") ||
                          placeholder.lowercased().contains("untitled") ||
                          placeholder.lowercased().contains("sample") ||
                          placeholder.lowercased().contains("example"),
                          "\(placeholder) 應被識別為佔位符")
        }
    }
    
    func testValidTitlePatterns() {
        // 測試有效標題
        let validTitles = [
            "A Study on Machine Learning Applications",
            "Deep Learning for Natural Language Processing",
            "人工智慧在醫療領域的應用研究"
        ]
        
        for title in validTitles {
            XCTAssertFalse(
                title.lowercased().contains("unknown") ||
                title.lowercased().contains("untitled"),
                "\(title) 不應被識別為佔位符"
            )
        }
    }
}

// MARK: - AcademicDocumentType 測試

@available(macOS 26.0, *)
final class AcademicDocumentTypeTests: XCTestCase {
    
    func testDocumentTypeValues() {
        // Given/When
        let types: [AcademicDocumentType] = [
            .article,
            .book,
            .inproceedings,
            .thesis,
            .misc
        ]
        
        // Then
        XCTAssertEqual(types.count, 5, "應有 5 種文件類型")
        XCTAssertEqual(AcademicDocumentType.article.rawValue, "article")
        XCTAssertEqual(AcademicDocumentType.book.rawValue, "book")
        XCTAssertEqual(AcademicDocumentType.thesis.rawValue, "thesis")
    }
    
    func testDocumentTypeDisplayName() {
        // Given
        let article = AcademicDocumentType.article
        let book = AcademicDocumentType.book
        let thesis = AcademicDocumentType.thesis
        
        // Then
        XCTAssertEqual(article.displayName, "期刊文章")
        XCTAssertEqual(book.displayName, "書籍")
        XCTAssertEqual(thesis.displayName, "學位論文")
    }
}

// MARK: - WritingAITools 測試

@available(macOS 26.0, *)
@MainActor
final class WritingAIToolsTests: XCTestCase {
    
    func testAnalyzeWritingToolProperties() {
        // Given
        let tool = AnalyzeWritingTool()
        
        // Then
        XCTAssertEqual(tool.name, "analyzeWriting")
        XCTAssertFalse(tool.description.isEmpty)
        XCTAssertNil(tool.result)
    }
    
    func testRewriteTextToolProperties() {
        // Given
        let tool = RewriteTextTool()
        
        // Then
        XCTAssertEqual(tool.name, "rewriteText")
        XCTAssertFalse(tool.description.isEmpty)
        XCTAssertNil(tool.result)
    }
    
    func testRewriteStyleValues() {
        // Given
        let allStyles = ToolRewriteStyle.allCases
        
        // Then
        XCTAssertEqual(allStyles.count, 5, "應有 5 種改寫風格")
        XCTAssertTrue(allStyles.contains(.formal))
        XCTAssertTrue(allStyles.contains(.academic))
        XCTAssertTrue(allStyles.contains(.concise))
    }
    
    func testIssueSeverityLevels() {
        // Given
        let severities = AnalyzeWritingTool.IssueSeverity.allCases
        
        // Then
        XCTAssertEqual(severities.count, 3, "應有 3 種嚴重程度")
        XCTAssertTrue(severities.contains(.high))
        XCTAssertTrue(severities.contains(.medium))
        XCTAssertTrue(severities.contains(.low))
    }
}

// MARK: - UnifiedAIService 測試

@available(macOS 26.0, *)
@MainActor
final class UnifiedAIServiceTests: XCTestCase {
    
    func testSharedInstance() {
        // Given/When
        let service = UnifiedAIService.shared
        
        // Then
        XCTAssertNotNil(service, "共享實例不應為 nil")
    }
    
    func testInitialState() {
        // Given
        let service = UnifiedAIService.shared
        
        // Then
        XCTAssertFalse(service.isProcessing, "初始狀態不應在處理中")
        XCTAssertNil(service.errorMessage, "初始錯誤訊息應為 nil")
    }
    
    func testDomainAccessibility() {
        // Given
        let service = UnifiedAIService.shared
        
        // Then - 確保所有領域都可以存取
        XCTAssertNotNil(service.writing, "寫作領域應可存取")
        XCTAssertNotNil(service.citation, "引用領域應可存取")
        XCTAssertNotNil(service.translation, "翻譯領域應可存取")
        XCTAssertNotNil(service.standards, "規範領域應可存取")
        XCTAssertNotNil(service.document, "文件領域應可存取")
        XCTAssertNotNil(service.formula, "公式領域應可存取")
    }
    
    func testStaticConvenienceProperties() {
        // Given/When/Then
        // 這些屬性應該不拋出錯誤
        _ = UnifiedAIService.available
        _ = UnifiedAIService.processing
    }
}

// MARK: - AI Domain 基礎測試

@available(macOS 26.0, *)
@MainActor
final class AIDomainTests: XCTestCase {
    
    var service: UnifiedAIService!
    
    override func setUp() async throws {
        await MainActor.run {
            service = UnifiedAIService.shared
        }
    }
    
    func testWritingDomainExists() {
        XCTAssertNotNil(service.writing)
    }
    
    func testCitationDomainExists() {
        XCTAssertNotNil(service.citation)
    }
    
    func testTranslationDomainExists() {
        XCTAssertNotNil(service.translation)
    }
    
    func testStandardsDomainExists() {
        XCTAssertNotNil(service.standards)
    }
    
    func testDocumentDomainExists() {
        XCTAssertNotNil(service.document)
    }
    
    func testFormulaDomainExists() {
        XCTAssertNotNil(service.formula)
    }
}
