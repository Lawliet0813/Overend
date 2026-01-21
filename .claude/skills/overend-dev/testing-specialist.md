# Testing Specialist - 測試撰寫與品質保證專家

## 職責範圍

負責所有測試相關工作，包括：
- 單元測試撰寫（Unit Tests）
- UI 測試撰寫（UI Tests）
- 測試資料準備
- 測試執行與報告解讀
- 測試覆蓋率分析
- 邊界案例設計

**不負責**：
- 功能實作（由其他 Specialist 處理）
- UI 設計（由 ui-specialist 處理）
- 資料模型設計（由 coredata-specialist 處理）

## 何時載入此 Skill

任務包含以下關鍵字時自動載入：
- 測試、Test、單元測試、UI 測試
- XCTest、XCTAssert
- 測試覆蓋率、Coverage
- Mock、Stub、Fake
- 測試資料、Test Data

## 測試架構

```
OVEREND/
├── OVERENDTests/              # 單元測試（12 個檔案）
│   ├── CitationServiceTests.swift       # 引用格式測試
│   ├── BibTeXParserTests.swift          # BibTeX 解析測試
│   ├── PDFMetadataExtractorTests.swift  # PDF 提取測試
│   ├── AiritiServiceTests.swift         # 華藝 DOI 測試
│   ├── AIServiceTests.swift             # AI 服務測試
│   ├── LiteratureAgentTests.swift       # 文獻 Agent 測試
│   ├── AgentTaskQueueTests.swift        # 任務佇列測試
│   ├── LearningServiceTests.swift       # 學習服務測試
│   ├── RepositoryTests.swift            # 資料存取測試
│   ├── NewFeaturesTests.swift           # 新功能測試
│   ├── CoreDataTestHelper.swift         # Core Data 測試工具
│   └── OVERENDTests.swift               # 測試範本
│
└── OVERENDUITests/            # UI 測試（4 個檔案）
    ├── EditorUITests.swift              # 編輯器 UI 測試
    ├── LibraryUITests.swift             # 文獻庫 UI 測試
    ├── OVERENDUITests.swift             # 通用 UI 測試
    └── OVERENDUITestsLaunchTests.swift  # 啟動測試
```

## 單元測試撰寫

### 測試類別範本

```swift
import XCTest
import CoreData
@testable import OVEREND

@MainActor
final class MyFeatureTests: XCTestCase {
    
    // 測試環境
    var testHelper: CoreDataTestHelper!
    var testContext: NSManagedObjectContext!
    var sut: MyService!  // System Under Test
    
    override func setUp() async throws {
        // 每個測試前執行
        await MainActor.run {
            testHelper = CoreDataTestHelper(inMemory: true)
            testContext = testHelper.viewContext
            sut = MyService()
        }
    }
    
    override func tearDown() async throws {
        // 每個測試後執行
        await MainActor.run {
            testHelper?.reset()
            testHelper = nil
            testContext = nil
            sut = nil
        }
    }
    
    func testFeatureName() {
        // Given - 準備測試資料
        let input = "test input"
        
        // When - 執行功能
        let result = sut.process(input)
        
        // Then - 驗證結果
        XCTAssertEqual(result, "expected output")
    }
}
```

### 命名規範

| 類型 | 規則 | 範例 |
|------|------|------|
| 測試類別 | `[功能名稱]Tests` | `CitationServiceTests` |
| 測試函數 | `test[功能描述]` | `testGenerateAPAForArticle` |
| 測試變數 | `sut` | System Under Test（被測試對象） |

### Given-When-Then 結構

```swift
func testCreateEntry() {
    // Given - 準備測試資料與環境
    let citationKey = "Chen2024"
    let title = "測試標題"
    let bibtexRaw = "@article{Chen2024,...}"
    
    // When - 執行要測試的功能
    let entry = Entry.create(
        in: testContext,
        citationKey: citationKey,
        bibtexRaw: bibtexRaw,
        entryType: "article",
        title: title
    )
    
    // Then - 驗證結果符合預期
    XCTAssertNotNil(entry)
    XCTAssertEqual(entry.citationKey, citationKey)
    XCTAssertEqual(entry.title, title)
    XCTAssertNotNil(entry.entryId)
    XCTAssertNotNil(entry.createdAt)
}
```

## Core Data 測試

### CoreDataTestHelper 使用

```swift
import CoreData

class CoreDataTestHelper {
    let persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    init(inMemory: Bool = true) {
        persistentContainer = NSPersistentContainer(name: "OVEREND")
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("無法載入測試資料庫：\(error)")
            }
        }
    }
    
    func reset() {
        let context = viewContext
        context.reset()
    }
}
```

### 測試 Core Data 操作

```swift
func testEntryCreation() {
    // Given
    let testHelper = CoreDataTestHelper(inMemory: true)
    let context = testHelper.viewContext
    
    // When
    let entry = Entry(context: context)
    entry.entryId = UUID()
    entry.citationKey = "Test2024"
    entry.bibtexRaw = "@article{Test2024,...}"
    entry.title = "測試標題"
    entry.createdAt = Date()
    entry.updatedAt = Date()
    
    try? context.save()
    
    // Then
    let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
    let results = try? context.fetch(fetchRequest)
    
    XCTAssertEqual(results?.count, 1)
    XCTAssertEqual(results?.first?.citationKey, "Test2024")
}
```

## Service 層測試

### CitationService 測試範例

```swift
final class CitationServiceTests: XCTestCase {
    var sut: CitationService!
    var testHelper: CoreDataTestHelper!
    var testContext: NSManagedObjectContext!
    
    override func setUp() {
        sut = CitationService.shared
        testHelper = CoreDataTestHelper(inMemory: true)
        testContext = testHelper.viewContext
    }
    
    func testGenerateAPAForArticle() {
        // Given
        let entry = Entry(context: testContext)
        entry.entryType = "article"
        entry.title = "深度學習應用"
        entry.authors = "陳一 and 李二"
        entry.year = "2024"
        entry.journal = "資訊管理學報"
        entry.volume = "31"
        entry.number = "2"
        entry.pages = "1-20"
        entry.doi = "10.1234/example"
        
        // When
        let citation = sut.generateAPA(entry: entry)
        
        // Then
        XCTAssertTrue(citation.contains("陳一、李二"))
        XCTAssertTrue(citation.contains("（2024）"))
        XCTAssertTrue(citation.contains("深度學習應用"))
        XCTAssertTrue(citation.contains("資訊管理學報"))
        XCTAssertTrue(citation.contains("31(2)"))
        XCTAssertTrue(citation.contains("1-20"))
        XCTAssertTrue(citation.contains("https://doi.org/10.1234/example"))
    }
    
    func testGenerateAPAForChineseArticle() {
        // Given
        let entry = Entry(context: testContext)
        entry.entryType = "article"
        entry.title = "中文論文標題"
        entry.authors = "王三 and 趙四 and 孫五"
        entry.year = "2024"
        
        // When
        let citation = sut.generateAPA(entry: entry)
        
        // Then
        // 超過兩位作者使用「等人」
        XCTAssertTrue(citation.contains("王三 等人"))
        XCTAssertFalse(citation.contains("趙四"))
        XCTAssertFalse(citation.contains("孫五"))
    }
}
```

### BibTeX Parser 測試

```swift
final class BibTeXParserTests: XCTestCase {
    func testParseValidBibTeX() throws {
        // Given
        let bibtexString = """
        @article{Chen2024,
            title = {測試標題},
            author = {陳一 and 李二},
            year = {2024},
            journal = {測試期刊}
        }
        """
        
        // When
        let entries = try BibTeXParser.parse(bibtexString)
        
        // Then
        XCTAssertEqual(entries.count, 1)
        
        let entry = entries[0]
        XCTAssertEqual(entry.type, "article")
        XCTAssertEqual(entry.citationKey, "Chen2024")
        XCTAssertEqual(entry.fields["title"], "測試標題")
        XCTAssertEqual(entry.fields["author"], "陳一 and 李二")
        XCTAssertEqual(entry.fields["year"], "2024")
    }
    
    func testParseInvalidBibTeX() {
        // Given
        let invalidBibTeX = "@article{Missing"  // 缺少結尾大括號
        
        // When & Then
        XCTAssertThrowsError(try BibTeXParser.parse(invalidBibTeX)) { error in
            XCTAssertTrue(error is ParsingError)
        }
    }
    
    func testParseMultipleEntries() throws {
        // Given
        let bibtexString = """
        @article{Chen2024,
            title = {第一篇},
            year = {2024}
        }
        @book{Wang2023,
            title = {第二篇},
            year = {2023}
        }
        """
        
        // When
        let entries = try BibTeXParser.parse(bibtexString)
        
        // Then
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].citationKey, "Chen2024")
        XCTAssertEqual(entries[1].citationKey, "Wang2023")
    }
}
```

## UI 測試

### UI 測試範本

```swift
import XCTest

final class LibraryUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testAddNewEntry() throws {
        // Given
        let addButton = app.buttons["新增書目"]
        
        // When
        addButton.tap()
        
        // Then
        let titleField = app.textFields["標題"]
        XCTAssertTrue(titleField.exists)
        XCTAssertTrue(titleField.isHittable)
    }
    
    func testSearchEntries() throws {
        // Given
        let searchField = app.searchFields["搜尋文獻"]
        
        // When
        searchField.tap()
        searchField.typeText("測試")
        
        // Then
        let results = app.tables["EntryList"]
        XCTAssertTrue(results.exists)
    }
}
```

### 使用 Accessibility Identifier

```swift
// 在 View 中設定
Button("新增") { }
    .accessibilityIdentifier("addButton")

Text("標題")
    .accessibilityIdentifier("titleLabel")

// 在測試中使用
let button = app.buttons["addButton"]
let label = app.staticTexts["titleLabel"]
```

## 測試資料準備

### 建立測試用 Entry

```swift
extension Entry {
    static func createTestEntry(
        in context: NSManagedObjectContext,
        citationKey: String = "Test2024",
        title: String = "測試標題",
        authors: String? = "測試作者",
        year: String? = "2024"
    ) -> Entry {
        let entry = Entry(context: context)
        entry.entryId = UUID()
        entry.citationKey = citationKey
        entry.bibtexRaw = "@article{\(citationKey),...}"
        entry.entryType = "article"
        entry.title = title
        entry.authors = authors
        entry.year = year
        entry.createdAt = Date()
        entry.updatedAt = Date()
        return entry
    }
}
```

### 建立測試用 BibTeX

```swift
struct TestBibTeX {
    static let article = """
    @article{Chen2024,
        title = {測試論文標題},
        author = {陳一 and 李二},
        year = {2024},
        journal = {資訊管理學報},
        volume = {31},
        number = {2},
        pages = {1--20},
        doi = {10.1234/example}
    }
    """
    
    static let book = """
    @book{Wang2023,
        title = {測試書籍標題},
        author = {王三},
        year = {2023},
        publisher = {測試出版社}
    }
    """
    
    static let invalid = """
    @article{Missing
    """  // 缺少結尾
}
```

## 測試執行指令

### 執行所有測試

```bash
cd /Users/lawliet/OVEREND
xcodebuild test -scheme OVEREND -destination 'platform=macOS'
```

### 只執行單元測試

```bash
xcodebuild test -scheme OVEREND -destination 'platform=macOS' -only-testing:OVERENDTests
```

### 執行特定測試類別

```bash
xcodebuild test -scheme OVEREND -destination 'platform=macOS' -only-testing:OVERENDTests/CitationServiceTests
```

### 執行特定測試函數

```bash
xcodebuild test -scheme OVEREND -destination 'platform=macOS' -only-testing:OVERENDTests/CitationServiceTests/testGenerateAPAForArticle
```

### 產生測試覆蓋率報告

```bash
xcodebuild test -scheme OVEREND -enableCodeCoverage YES -destination 'platform=macOS'
```

## 測試報告解讀

### 成功的測試輸出

```
Test Suite 'CitationServiceTests' started
✅ testGenerateAPAForArticle (0.001 秒)
✅ testGenerateAPAForBook (0.001 秒)
✅ testGenerateAPAForChineseArticle (0.002 秒)

Test Suite 'CitationServiceTests' finished
總共：3 個測試
通過：3 個 ✅
失敗：0 個
時間：0.004 秒
```

### 失敗的測試輸出

```
Test Suite 'BibTeXParserTests' started
✅ testParseValidBibTeX (0.001 秒)
❌ testParseInvalidBibTeX (0.002 秒)
   /Users/lawliet/OVEREND/OVERENDTests/BibTeXParserTests.swift:45
   XCTAssertThrowsError failed: did not throw an error
   
Test Suite 'BibTeXParserTests' finished
總共：2 個測試
通過：1 個 ✅
失敗：1 個 ❌
時間：0.003 秒
```

## 測試覆蓋率指南

### 優先級分類

**高優先級（必須測試）**：
- 核心業務邏輯（CitationService、BibTeXParser）
- 資料轉換與解析
- 錯誤處理與邊界條件
- Core Data CRUD 操作

**中優先級（建議測試）**：
- 資料存取層（Repositories）
- API 整合（DOIService、CrossRefService）
- PDF 處理邏輯

**低優先級（選擇性測試）**：
- UI 顯示邏輯
- 簡單 getter/setter
- 預設值設定

### 目標覆蓋率

- **整體專案**：≥ 60%
- **Service 層**：≥ 80%
- **Core Data 模型**：≥ 70%
- **UI 層**：≥ 40%

## 常見測試模式

### 1. 邊界條件測試

```swift
func testEmptyInput() {
    let result = sut.process("")
    XCTAssertEqual(result, "")
}

func testNilInput() {
    let result = sut.process(nil)
    XCTAssertNil(result)
}

func testLargeInput() {
    let largeString = String(repeating: "a", count: 10000)
    let result = sut.process(largeString)
    XCTAssertNotNil(result)
}
```

### 2. 錯誤處理測試

```swift
func testThrowsError() {
    XCTAssertThrowsError(try sut.parseInvalid()) { error in
        XCTAssertTrue(error is ParsingError)
    }
}

func testDoesNotThrow() {
    XCTAssertNoThrow(try sut.parseValid())
}
```

### 3. 非同步測試

```swift
func testAsyncOperation() async throws {
    let expectation = XCTestExpectation(description: "Async operation")
    
    Task {
        let result = await sut.fetchData()
        XCTAssertNotNil(result)
        expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
}
```

## 整合檢查清單

### 撰寫新測試時

- [ ] 使用 Given-When-Then 結構
- [ ] 測試函數命名清楚（test + 功能描述）
- [ ] 每個測試只驗證一件事
- [ ] 包含正常情況與邊界條件
- [ ] 測試錯誤處理邏輯
- [ ] setUp 和 tearDown 正確實作
- [ ] Core Data 使用 in-memory store
- [ ] 編譯通過
- [ ] 所有測試都能獨立執行

### 與其他 Skill 協作

**與 UI Specialist 協作**：
- 使用 accessibilityIdentifier 標記元件
- 測試 UI 互動流程
- 驗證深色/淺色模式

**與 Core Data Specialist 協作**：
- 使用 CoreDataTestHelper
- 測試模型建立、更新、刪除
- 驗證關聯關係

**與 Service Specialist 協作**：
- Mock API 回應
- 測試錯誤處理
- 驗證資料解析正確性

## 常見問題

### Q: 測試失敗但本地可執行？

```
可能原因：
1. 測試依賴順序（修改為獨立測試）
2. 共用狀態污染（檢查 setUp/tearDown）
3. 非同步執行問題（使用 expectation）
4. Core Data context 未正確清理
```

### Q: 如何 Mock API 回應？

```swift
class MockCrossRefService: CrossRefService {
    var shouldReturnError = false
    var mockMetadata: CrossRefMetadata?
    
    override func fetchMetadata(doi: String) async throws -> CrossRefMetadata {
        if shouldReturnError {
            throw ServiceError.notFound
        }
        return mockMetadata ?? CrossRefMetadata(...)
    }
}
```

### Q: Core Data 測試資料如何清理？

```swift
override func tearDown() async throws {
    await MainActor.run {
        testHelper?.reset()  // 清空 context
        testHelper = nil
        testContext = nil
    }
}
```

---

**版本**: 1.0
**建立日期**: 2025-01-21
**維護者**: OVEREND 開發團隊
