//
//  CitationServiceTests.swift
//  OVERENDTests
//
//  引用服務單元測試 - APA, MLA, Chicago 格式
//

import XCTest
import CoreData
@testable import OVEREND

@MainActor
final class CitationServiceTests: XCTestCase {
    
    var testHelper: CoreDataTestHelper!
    var testContext: NSManagedObjectContext!
    var testLibrary: Library!
    
    override func setUp() async throws {
        await MainActor.run {
            testHelper = CoreDataTestHelper(inMemory: true)
            testContext = testHelper.viewContext
            testLibrary = testHelper.createTestLibrary(name: "Test Library", isDefault: true)
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            testHelper?.reset()
            testHelper = nil
            testContext = nil
            testLibrary = nil
        }
    }
    
    // MARK: - 建立測試 Entry
    
    private func createTestEntry(
        citationKey: String = "Smith2024",
        entryType: String = "article",
        fields: [String: String]
    ) -> Entry {
        return Entry(
            context: testContext,
            citationKey: citationKey,
            entryType: entryType,
            fields: fields,
            library: testLibrary
        )
    }
    
    // MARK: - APA 格式測試
    
    func testGenerateAPAForArticle() {
        // Given
        let entry = createTestEntry(fields: [
            "author": "Smith, John and Doe, Jane",
            "title": "A Study on Machine Learning",
            "year": "2024",
            "journal": "Journal of AI Research",
            "volume": "15",
            "pages": "123-145",
            "doi": "10.1234/jair.2024"
        ])
        
        // When
        let citation = CitationService.generateAPA(entry: entry)
        
        // Then
        XCTAssertTrue(citation.contains("Smith"), "應包含作者姓氏")
        XCTAssertTrue(citation.contains("2024"), "應包含年份")
        XCTAssertTrue(citation.contains("Machine Learning"), "應包含標題")
        XCTAssertTrue(citation.contains("Journal of AI Research"), "應包含期刊名")
    }
    
    func testGenerateAPAForBook() {
        // Given
        let entry = createTestEntry(
            entryType: "book",
            fields: [
                "author": "Johnson, Michael",
                "title": "Advanced Swift Programming",
                "year": "2023",
                "publisher": "Tech Books Inc."
            ]
        )
        
        // When
        let citation = CitationService.generateAPA(entry: entry)
        
        // Then
        XCTAssertTrue(citation.contains("Johnson"), "應包含作者姓氏")
        XCTAssertTrue(citation.contains("2023"), "應包含年份")
        XCTAssertTrue(citation.contains("Advanced Swift"), "應包含書名")
        XCTAssertTrue(citation.contains("Tech Books"), "應包含出版社")
    }
    
    func testGenerateAPAForChineseArticle() {
        // Given
        let entry = createTestEntry(fields: [
            "author": "王小明、李大華",
            "title": "人工智慧在醫療診斷的應用研究",
            "year": "2024",
            "journal": "台灣人工智慧學刊",
            "volume": "5",
            "pages": "1-20"
        ])
        
        // When
        let citation = CitationService.generateAPA(entry: entry)
        
        // Then
        XCTAssertTrue(citation.contains("王小明") || citation.contains("王"), "應包含中文作者")
        XCTAssertTrue(citation.contains("2024"), "應包含年份")
        XCTAssertTrue(citation.contains("人工智慧"), "應包含標題關鍵字")
    }
    
    func testGenerateAPAWithMultipleAuthors() {
        // Given
        let entry = createTestEntry(fields: [
            "author": "Smith, John and Doe, Jane and Brown, Robert",
            "title": "Collaborative Research Methods",
            "year": "2024",
            "journal": "Research Quarterly"
        ])
        
        // When
        let citation = CitationService.generateAPA(entry: entry)
        
        // Then
        XCTAssertTrue(citation.contains("Smith"), "應包含第一作者")
        // APA 格式多作者使用 & 或 and
        XCTAssertTrue(citation.contains("&") || citation.contains("and") || citation.contains(","), 
                      "多作者應有連接符號")
    }
    
    func testGenerateAPAWithDOI() {
        // Given
        let entry = createTestEntry(fields: [
            "author": "Lee, Sarah",
            "title": "DOI Integration Study",
            "year": "2024",
            "journal": "Digital Research",
            "doi": "10.5678/dr.2024.001"
        ])
        
        // When
        let citation = CitationService.generateAPA(entry: entry)
        
        // Then
        XCTAssertTrue(citation.contains("doi.org") || citation.contains("10.5678"), 
                      "應包含 DOI 連結或編號")
    }
    
    func testGenerateAPAWithMissingFields() {
        // Given - 只有必要欄位
        let entry = createTestEntry(fields: [
            "author": "Unknown Author",
            "title": "Minimal Article"
        ])
        
        // When
        let citation = CitationService.generateAPA(entry: entry)
        
        // Then
        XCTAssertFalse(citation.isEmpty, "即使缺欄位也應產生引用")
        XCTAssertTrue(citation.contains("Minimal Article"), "應包含標題")
    }
    
    // MARK: - MLA 格式測試
    
    func testGenerateMLAForArticle() {
        // Given
        let entry = createTestEntry(fields: [
            "author": "Williams, Emma",
            "title": "Literature Analysis Methods",
            "year": "2023",
            "journal": "Literary Review",
            "volume": "42",
            "pages": "55-78"
        ])
        
        // When
        let citation = CitationService.generateMLA(entry: entry)
        
        // Then
        XCTAssertTrue(citation.contains("Williams"), "應包含作者姓氏")
        XCTAssertTrue(citation.contains("Literature Analysis"), "應包含標題")
        // MLA 格式標題通常有引號
        XCTAssertTrue(citation.contains("\"") || citation.contains("*"), 
                      "MLA 標題應有格式標記")
    }
    
    func testGenerateMLAForBook() {
        // Given
        let entry = createTestEntry(
            entryType: "book",
            fields: [
                "author": "Garcia, Carlos",
                "title": "Modern Poetry",
                "year": "2022",
                "publisher": "Literature Press"
            ]
        )
        
        // When
        let citation = CitationService.generateMLA(entry: entry)
        
        // Then
        XCTAssertTrue(citation.contains("Garcia"), "應包含作者")
        XCTAssertTrue(citation.contains("Modern Poetry"), "應包含書名")
    }
    
    // MARK: - 邊界情況測試
    
    func testGenerateCitationWithEmptyAuthor() {
        // Given
        let entry = createTestEntry(fields: [
            "author": "",
            "title": "Anonymous Work",
            "year": "2024"
        ])
        
        // When
        let citation = CitationService.generateAPA(entry: entry)
        
        // Then
        XCTAssertFalse(citation.isEmpty, "空作者也應產生引用")
    }
    
    func testGenerateCitationWithSpecialCharacters() {
        // Given
        let entry = createTestEntry(fields: [
            "author": "O'Brien, Patrick",
            "title": "Special Characters: A Study & Analysis",
            "year": "2024",
            "journal": "J. of Testing"
        ])
        
        // When
        let citation = CitationService.generateAPA(entry: entry)
        
        // Then
        XCTAssertTrue(citation.contains("O'Brien") || citation.contains("Brien"), 
                      "應正確處理特殊字元")
    }
}

// MARK: - 作者格式化測試

@MainActor
final class AuthorFormattingTests: XCTestCase {
    
    var testHelper: CoreDataTestHelper!
    
    override func setUp() async throws {
        await MainActor.run {
            testHelper = CoreDataTestHelper(inMemory: true)
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            testHelper?.reset()
            testHelper = nil
        }
    }
    
    func testSingleAuthorFormatting() {
        // Given
        let singleAuthor = "Smith, John"
        
        let library = testHelper.createTestLibrary()
        let entry = Entry(
            context: testHelper.viewContext,
            citationKey: "test",
            entryType: "article",
            fields: ["author": singleAuthor, "title": "Test", "year": "2024"],
            library: library
        )
        
        // When
        let citation = CitationService.generateAPA(entry: entry)
        
        // Then
        XCTAssertTrue(citation.contains("Smith"), "應包含姓氏")
    }
}
