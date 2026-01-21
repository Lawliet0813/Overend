//
//  NewFeaturesTests.swift
//  OVERENDTests
//
//  新功能測試案例
//  測試 ChineseNameFormatter、CitationJSBridge、CitationService 等新增功能
//

import XCTest
@testable import OVEREND

final class ChineseNameFormatterTests: XCTestCase {
    
    let formatter = ChineseNameFormatter.shared
    
    // MARK: - 中文姓名解析測試
    
    func testParseSingleChineseName() {
        let parsed = formatter.parse("王大明")
        XCTAssertEqual(parsed.family, "王")
        XCTAssertEqual(parsed.given, "大明")
        XCTAssertEqual(parsed.language, .chinese)
    }
    
    func testParseCompoundSurname() {
        let parsed = formatter.parse("歐陽菲菲")
        XCTAssertEqual(parsed.family, "歐陽")
        XCTAssertEqual(parsed.given, "菲菲")
        XCTAssertEqual(parsed.language, .chinese)
    }
    
    func testParseEnglishName() {
        let parsed = formatter.parse("John Smith")
        XCTAssertEqual(parsed.family, "Smith")
        XCTAssertTrue(parsed.given.contains("John"))
        XCTAssertEqual(parsed.language, .english)
    }
    
    func testParseEnglishNameWithMiddle() {
        let parsed = formatter.parse("John Michael Smith")
        XCTAssertEqual(parsed.family, "Smith")
        XCTAssertTrue(parsed.given.contains("John"))
        XCTAssertEqual(parsed.language, .english)
    }
    
    // MARK: - APA 格式測試
    
    func testAPAFormatChinese() {
        let parsed = formatter.parse("王大明")
        XCTAssertFalse(parsed.apaFormat.isEmpty)
        // 中文姓名應完整呈現
        XCTAssertTrue(parsed.apaFormat.contains("王"))
    }
    
    func testAPAFormatEnglish() {
        let parsed = formatter.parse("John Smith")
        // 英文 APA 格式: Smith, J.
        XCTAssertTrue(parsed.apaFormat.contains("Smith"))
    }
    
    // MARK: - 多作者格式化測試
    
    func testMultipleChineseAuthors() {
        let authorsString = "王大明、李小華、張三豐"
        let names = formatter.parseAuthors(authorsString)
        XCTAssertEqual(names.count, 3)
    }
    
    func testMultipleEnglishAuthors() {
        let authorsString = "John Smith and Jane Doe"
        let names = formatter.parseAuthors(authorsString)
        XCTAssertEqual(names.count, 2)
    }
    
    // MARK: - 複姓識別測試
    
    func testCompoundSurnameRecognition() {
        let compoundSurnames = ["歐陽修", "司馬遷", "諸葛亮"]
        
        for name in compoundSurnames {
            let parsed = formatter.parse(name)
            XCTAssertEqual(parsed.family.count, 2, "複姓 \(name) 應被識別為雙字複姓")
        }
    }
    
    // MARK: - 消歧義測試
    
    func testNeedsDisambiguation() {
        let name1 = formatter.parse("王大明")
        let name2 = formatter.parse("王大偉")
        
        let needsDisambiguation = formatter.needsDisambiguation(name1, name2)
        XCTAssertTrue(needsDisambiguation, "同姓且名字首字相同應需要消歧義")
    }
}

// MARK: - Citation.js Bridge 測試

final class CitationJSBridgeTests: XCTestCase {
    
    var bridge: CitationJSBridge!
    
    override func setUp() {
        super.setUp()
        bridge = CitationJSBridge.shared
    }
    
    // MARK: - BibTeX 解析測試
    
    func testParseBibTeX() throws {
        let bibtex = """
        @article{smith2020,
            author = {John Smith and Jane Doe},
            title = {A Study of Testing},
            journal = {Journal of Tests},
            year = {2020},
            volume = {10},
            pages = {1-20}
        }
        """
        
        let entries = try bridge.parse(bibtex, format: .bibtex)
        XCTAssertEqual(entries.count, 1)
        
        let entry = entries[0]
        XCTAssertEqual(entry.title, "A Study of Testing")
    }
    
    // MARK: - RIS 解析測試
    
    func testParseRIS() throws {
        let ris = """
        TY  - JOUR
        AU  - Smith, John
        AU  - Doe, Jane
        TI  - A Study of Testing
        JO  - Journal of Tests
        PY  - 2020
        VL  - 10
        SP  - 1
        EP  - 20
        ER  -
        """
        
        let entries = try bridge.parse(ris, format: .ris)
        XCTAssertEqual(entries.count, 1)
    }
    
    // MARK: - 格式自動偵測測試
    
    func testAutoDetectBibTeX() throws {
        let bibtex = "@article{test, title = {Test}}"
        let entries = try bridge.parse(bibtex, format: .auto)
        XCTAssertEqual(entries.count, 1)
    }
}

// MARK: - CitationService 進階功能測試

final class CitationServiceAdvancedTests: XCTestCase {
    
    // MARK: - 進階作者格式化測試
    
    func testFormatAuthorsAdvanced() {
        let authorString = "王大明、李小華"
        let formatted = CitationService.shared.formatAuthorsAdvanced(
            authorString,
            fields: [:],
            style: .apa7
        )
        
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.contains("王") || formatted.contains("大明"))
    }
    
    func testFormatSingleAuthorAdvanced() {
        let authorName = "歐陽菲菲"
        let formatted = CitationService.shared.formatSingleAuthorAdvanced(
            authorName,
            style: .apa7,
            disambiguate: false
        )
        
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.contains("歐陽"))
    }
}
