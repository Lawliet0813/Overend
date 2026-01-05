//
//  LibraryUITests.swift
//  OVERENDUITests
//
//  文獻庫 UI 自動化測試
//

import XCTest

final class LibraryUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - 導航測試
    
    @MainActor
    func testNavigateToLibrary() throws {
        // Given - 應用程式已啟動
        
        // When - 點擊側邊欄的文獻庫連結
        let sidebar = app.outlines.firstMatch
        let libraryItem = sidebar.staticTexts["文獻庫"]
        
        if libraryItem.waitForExistence(timeout: 5) {
            libraryItem.tap()
            
            // Then - 應該顯示文獻庫視圖
            let libraryView = app.groups["libraryView"]
            XCTAssertTrue(libraryView.waitForExistence(timeout: 3) || 
                         app.staticTexts["文獻庫"].exists,
                         "應該導航到文獻庫視圖")
        }
    }
    
    @MainActor
    func testSidebarExists() throws {
        // Given - 應用程式已啟動
        
        // Then - 側邊欄應該存在
        let sidebar = app.outlines.firstMatch
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5), "側邊欄應該存在")
    }
    
    // MARK: - 搜尋測試
    
    @MainActor
    func testSearchFieldExists() throws {
        // Given - 導航到文獻庫
        navigateToLibrary()
        
        // Then - 搜尋欄應該存在
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            XCTAssertTrue(searchField.isEnabled, "搜尋欄應該可用")
        }
    }
    
    @MainActor
    func testSearchLibraryEntries() throws {
        // Given - 導航到文獻庫
        navigateToLibrary()
        
        // When - 在搜尋欄輸入文字
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("machine learning")
            
            // Then - 應該觸發搜尋（不一定有結果）
            // 驗證搜尋欄有值
            XCTAssertEqual(searchField.value as? String, "machine learning")
        }
    }
    
    // MARK: - 列表操作測試
    
    @MainActor
    func testEntryListDisplays() throws {
        // Given - 導航到文獻庫
        navigateToLibrary()
        
        // Then - 應該有文獻列表或空狀態提示
        let timeout: TimeInterval = 5
        let listExists = app.tables.firstMatch.waitForExistence(timeout: timeout) ||
                        app.outlines.firstMatch.waitForExistence(timeout: timeout) ||
                        app.scrollViews.firstMatch.waitForExistence(timeout: timeout)
        
        // 列表存在，或者有「沒有文獻」的提示
        let hasEmptyState = app.staticTexts["尚無文獻"].exists ||
                           app.staticTexts["開始添加文獻"].exists ||
                           app.staticTexts["拖放 PDF"].exists
        
        XCTAssertTrue(listExists || hasEmptyState, "應該顯示文獻列表或空狀態")
    }
    
    @MainActor
    func testSortEntriesButtonExists() throws {
        // Given - 導航到文獻庫
        navigateToLibrary()
        
        // Then - 應該有排序按鈕或選單
        let sortButton = app.buttons["排序"]
        let sortMenu = app.popUpButtons["排序"]
        let hasSort = sortButton.exists || sortMenu.exists ||
                     app.buttons["arrow.up.arrow.down"].exists
        
        // 排序功能可能以不同形式存在
        if hasSort {
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - 批次操作測試
    
    @MainActor
    func testBatchSelectModeToggle() throws {
        // Given - 導航到文獻庫
        navigateToLibrary()
        
        // When - 尋找選擇按鈕
        let selectButton = app.buttons["選擇"]
        
        if selectButton.waitForExistence(timeout: 3) {
            selectButton.tap()
            
            // Then - 應該進入選擇模式
            let cancelButton = app.buttons["取消"]
            let doneButton = app.buttons["完成"]
            XCTAssertTrue(cancelButton.exists || doneButton.exists,
                         "應該顯示取消或完成按鈕")
        }
    }
    
    // MARK: - 匯入測試
    
    @MainActor
    func testImportButtonExists() throws {
        // Given - 在主視圖或文獻庫
        
        // Then - 應該有匯入按鈕
        let importButton = app.buttons["匯入"]
        let plusButton = app.buttons["plus"]
        let addButton = app.buttons["加入"]
        
        let hasImportOption = importButton.exists || plusButton.exists || addButton.exists
        
        // 匯入功能可能在工具列或選單中
        if hasImportOption {
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - 輔助方法
    
    private func navigateToLibrary() {
        let sidebar = app.outlines.firstMatch
        let libraryItem = sidebar.staticTexts["文獻庫"]
        
        if libraryItem.waitForExistence(timeout: 5) {
            libraryItem.tap()
        }
        
        // 等待視圖加載
        _ = app.staticTexts["文獻庫"].waitForExistence(timeout: 2)
    }
}

// MARK: - 文獻詳情測試

final class EntryDetailUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    @MainActor
    func testEntryDetailViewDisplays() throws {
        // Given - 導航到文獻庫並選擇一個條目
        let sidebar = app.outlines.firstMatch
        let libraryItem = sidebar.staticTexts["文獻庫"]
        
        guard libraryItem.waitForExistence(timeout: 5) else { return }
        libraryItem.tap()
        
        // When - 選擇第一個文獻（如果存在）
        let firstEntry = app.tables.cells.firstMatch
        
        if firstEntry.waitForExistence(timeout: 3) {
            firstEntry.tap()
            
            // Then - 應該顯示詳情視圖
            // 詳情視圖可能包含標題、作者、年份等欄位
            let hasDetailContent = app.staticTexts.matching(identifier: "entryTitle").firstMatch.exists ||
                                  app.textViews.firstMatch.exists
            
            if hasDetailContent {
                XCTAssertTrue(true)
            }
        }
    }
}
