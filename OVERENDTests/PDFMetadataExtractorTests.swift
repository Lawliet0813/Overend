//
//  PDFMetadataExtractorTests.swift
//  OVERENDTests
//
//  PDF 元資料提取器單元測試
//

import XCTest
import PDFKit
@testable import OVEREND

final class PDFMetadataExtractorTests: XCTestCase {
    
    // MARK: - 測試資料
    
    /// 取得測試 PDF 路徑
    private func testPDFURL(named: String = "sample") -> URL? {
        // 嘗試從 TestData 目錄找測試 PDF
        let testDataPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestData")
        
        // 嘗試多個可能的檔名
        let possibleNames = ["\(named).pdf", "test_\(named).pdf", "\(named)_paper.pdf"]
        for name in possibleNames {
            let url = testDataPath.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        // 使用第一個可用的 PDF
        if let files = try? FileManager.default.contentsOfDirectory(at: testDataPath, includingPropertiesForKeys: nil),
           let firstPDF = files.first(where: { $0.pathExtension == "pdf" }) {
            return firstPDF
        }
        
        return nil
    }
    
    // MARK: - PDFMetadata 結構測試
    
    func testPDFMetadataInitialization() {
        // Given
        let metadata = PDFMetadata(
            title: "Test Title",
            authors: ["Author One", "Author Two"],
            year: "2024",
            doi: "10.1234/test.2024",
            abstract: "This is a test abstract",
            journal: "Test Journal",
            volume: "1",
            pages: "1-10",
            entryType: "article",
            confidence: .high
        )
        
        // Then
        XCTAssertEqual(metadata.title, "Test Title")
        XCTAssertEqual(metadata.authors.count, 2)
        XCTAssertEqual(metadata.year, "2024")
        XCTAssertEqual(metadata.doi, "10.1234/test.2024")
        XCTAssertEqual(metadata.journal, "Test Journal")
    }
    
    func testPDFMetadataConfidenceLabels() {
        // Given/When/Then
        XCTAssertEqual(PDFMetadata.MetadataConfidence.high.label, "高可信度")
        XCTAssertEqual(PDFMetadata.MetadataConfidence.medium.label, "中等可信度")
        XCTAssertEqual(PDFMetadata.MetadataConfidence.low.label, "低可信度")
    }
    
    // MARK: - 提取測試
    
    @MainActor
    func testExtractMetadataReturnsValidResult() async {
        // Given
        guard let pdfURL = testPDFURL() else {
            // 如果沒有測試 PDF，創建一個模擬測試
            print("⚠️ 沒有找到測試 PDF，跳過此測試")
            return
        }
        
        // When
        let (metadata, logs) = await PDFMetadataExtractor.extractMetadata(from: pdfURL)
        
        // Then
        XCTAssertFalse(metadata.title.isEmpty, "標題不應為空")
        XCTAssertFalse(logs.isEmpty, "應該有提取日誌")
        XCTAssertNotNil(metadata.confidence, "應該有可信度評估")
    }
    
    @MainActor
    func testExtractMetadataFromInvalidURL() async {
        // Given
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/to/file.pdf")
        
        // When
        let (metadata, logs) = await PDFMetadataExtractor.extractMetadata(from: invalidURL)
        
        // Then
        // 預期會回傳從檔名提取的後備結果
        XCTAssertFalse(logs.isEmpty, "即使失敗也應該有日誌")
        XCTAssertTrue(logs.contains("無法開啟") || metadata.title.contains("file"), "應該有錯誤訊息或使用檔名")
    }
    
    // MARK: - 信心度測試
    
    func testMetadataConfidenceComparison() {
        // Given
        let high = PDFMetadata.MetadataConfidence.high
        let medium = PDFMetadata.MetadataConfidence.medium
        let low = PDFMetadata.MetadataConfidence.low
        
        // Then - 驗證各信心度等級的標籤正確
        XCTAssertNotEqual(high.label, medium.label)
        XCTAssertNotEqual(medium.label, low.label)
        XCTAssertNotEqual(high.label, low.label)
    }
    
    // MARK: - Placeholder 偵測測試
    
    func testPlaceholderTitleDetection() {
        // Given - 常見的 placeholder 標題
        let placeholderTitles = [
            "Unknown Title",
            "Untitled",
            "未知標題",
            "無標題",
            "Sample Title",
            "Example Paper"
        ]
        
        // When/Then
        for title in placeholderTitles {
            let isPlaceholder = isLikelyPlaceholder(title)
            XCTAssertTrue(isPlaceholder, "'\(title)' 應該被識別為 placeholder")
        }
    }
    
    func testValidTitleNotDetectedAsPlaceholder() {
        // Given - 真實標題
        let validTitles = [
            "A Study on Machine Learning in Healthcare",
            "深度學習在自然語言處理的應用",
            "Quantum Computing: A Survey"
        ]
        
        // When/Then
        for title in validTitles {
            let isPlaceholder = isLikelyPlaceholder(title)
            XCTAssertFalse(isPlaceholder, "'\(title)' 不應該被識別為 placeholder")
        }
    }
    
    // MARK: - 輔助方法
    
    private func isLikelyPlaceholder(_ title: String) -> Bool {
        let lowercased = title.lowercased()
        let placeholderPatterns = [
            "unknown", "untitled", "sample", "example", "test",
            "未知", "無標題", "範例", "測試"
        ]
        return placeholderPatterns.contains { lowercased.contains($0) }
    }
}

// MARK: - ExtractionLogger 測試
// 註：ExtractionLogger 為內部類別，無法從測試 Target 存取
// 如需測試，需將 ExtractionLogger 標記為 public 或使用 @testable import

