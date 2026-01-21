# AI 測試框架使用指南

## 📋 概述

OVEREND AI 測試框架是一個完整的測試解決方案，專為測試應用中的 AI 功能設計。框架提供：

- ✅ **統一的測試介面** - 透過協議定義標準化的測試流程
- ✅ **Mock AI 服務** - 無需真實 AI 即可進行測試
- ✅ **自動報告生成** - 支援 Markdown 和 JSON 格式
- ✅ **測試資料生成器** - 快速生成測試數據
- ✅ **豐富的斷言工具** - 專為 AI 測試設計的斷言方法

---

## 🏗️ 架構

```
OVERENDTests/AI/
├── AITestFramework.swift              # 核心框架
├── CitationDomainTests.swift          # 引用領域測試
├── WritingDomainTests.swift           # 寫作領域測試
├── DocumentDomainTests.swift          # 文件處理領域測試
├── AIFrameworkIntegrationTests.swift  # 整合測試
└── README.md                          # 本文檔
```

### 核心組件

1. **AITestFramework.swift**
   - `AITestCase` - 測試用例協議
   - `AIToolTestable` - 工具測試協議
   - `AIDomainTestable` - 領域測試協議
   - `MockAIService` - Mock AI 服務
   - `AITestDataGenerator` - 測試資料生成器
   - `AITestAssertions` - 測試斷言工具
   - `AITestReporter` - 測試報告生成器
   - `AITestRunner` - 測試執行器

2. **領域測試套件**
   - `CitationDomainTests` - 引用功能測試
   - `WritingDomainTests` - 寫作功能測試
   - `DocumentDomainTests` - 文件處理功能測試

---

## 🚀 快速開始

### 1. 執行所有測試

```bash
# 在 Xcode 中
⌘ + U

# 或使用命令行
xcodebuild test -project OVEREND.xcodeproj \
  -scheme OVEREND \
  -only-testing:OVERENDTests/AIFrameworkIntegrationTests
```

### 2. 執行單一領域測試

```swift
// 在測試類中
func testCitationFeatures() async throws {
    let domain = CitationDomainTests()
    let report = try await domain.testAllFeatures()
    
    print(report.summary)
    XCTAssertGreaterThanOrEqual(report.successRate, 80.0)
}
```

### 3. 自訂測試配置

```swift
var config = AITestConfiguration()
config.useRealAIService = false        // 使用 Mock
config.timeout = 30                    // 30 秒超時
config.generateReport = true           // 生成報告
config.reportOutputPath = "./report.md"
config.verboseLogging = true           // 詳細日誌
config.parallelTestCount = 3           // 並行數量
config.stopOnFailure = false           // 失敗不停止

let runner = AITestRunner(config: config)
```

---

## 📝 建立新的測試

### 步驟 1: 實現 AIDomainTestable 協議

```swift
@MainActor
final class MyNewDomainTests: XCTestCase, AIDomainTestable {
    
    var domainName: String { "My New Domain" }
    
    private var mockAI: MockAIService!
    private var testResults: [AITestResult] = []
    
    override func setUp() async throws {
        try await super.setUp()
        mockAI = MockAIService()
        testResults = []
        
        // 設定 Mock 回應
        mockAI.mockResponses["my_tool"] = "Mock response"
    }
    
    override func tearDown() async throws {
        mockAI = nil
        testResults = []
        try await super.tearDown()
    }
    
    func testAllFeatures() async throws -> DomainTestReport {
        let startTime = Date()
        
        // 執行測試
        await testMyFeature()
        
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
}
```

### 步驟 2: 實現測試用例

```swift
func testMyFeature() async throws {
    let testID = "my_feature_001"
    let startTime = Date()
    
    do {
        let input = "test input"
        let response = try await mockAI.processRequest(input, tool: "my_tool")
        
        // 使用斷言工具驗證
        AITestAssertions.assertNotEmpty(response)
        AITestAssertions.assertContains(response, keywords: ["expected"])
        
        testResults.append(AITestResult(
            testID: testID,
            testName: "測試我的功能",
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
            testName: "測試我的功能",
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
```

### 步驟 3: 加入到整合測試

```swift
func testRunAllDomains() async throws {
    let domains: [AIDomainTestable] = [
        CitationDomainTests(),
        WritingDomainTests(),
        DocumentDomainTests(),
        MyNewDomainTests()  // 新增的領域
    ]
    
    try await testRunner.runAllTests(domains: domains)
}
```

---

## 🛠️ 工具與輔助類

### Mock AI 服務

```swift
let mockAI = MockAIService()

// 設定是否成功
mockAI.shouldSucceed = true

// 設定回應延遲
mockAI.responseDelay = 0.1

// 設定自訂回應
mockAI.mockResponses["tool_name"] = "Expected response"

// 使用
let response = try await mockAI.processRequest("input", tool: "tool_name")
```

### 測試資料生成器

```swift
// 生成 BibTeX 條目
let bibtex = AITestDataGenerator.generateBibTeXEntry(key: "smith2024")

// 生成論文內容
let paperZh = AITestDataGenerator.generatePaperContent(language: "zh")
let paperEn = AITestDataGenerator.generatePaperContent(language: "en")

// 生成 PDF 元資料
let metadata = AITestDataGenerator.generatePDFMetadata()

// 生成引用文字
let citationAPA = AITestDataGenerator.generateCitationText(style: "apa")
let citationIEEE = AITestDataGenerator.generateCitationText(style: "ieee")
```

### 測試斷言

```swift
// 驗證回應不為空
AITestAssertions.assertNotEmpty(response)

// 驗證包含關鍵字
AITestAssertions.assertContains(response, keywords: ["AI", "test"])

// 驗證 JSON 格式
AITestAssertions.assertValidJSON(jsonString)

// 驗證執行時間
let result = try await AITestAssertions.assertExecutionTime({
    // 執行一些操作
    return result
}, maxDuration: 5.0)
```

---

## 📊 測試報告

### Markdown 報告範例

```markdown
# AI 測試報告

生成時間: 2026-01-19 23:30:00

---

## 📊 總體概覽

| 指標 | 數值 |
|------|------|
| 測試領域數 | 3 |
| 總測試數 | 16 |
| 通過 ✅ | 14 |
| 失敗 ❌ | 2 |
| 成功率 | 87.5% |

## 📋 領域測試詳情

### Citation Domain

📊 領域測試報告: Citation Domain
────────────────────────────
總測試數: 5
通過: 5 ✅
失敗: 0 ❌
跳過: 0 ⏭️
錯誤: 0 ⚠️
成功率: 100.0%
耗時: 1.23s
```

### JSON 報告範例

```json
{
  "timestamp": "2026-01-19T23:30:00Z",
  "domains": [
    {
      "name": "Citation Domain",
      "totalTests": 5,
      "passedTests": 5,
      "failedTests": 0,
      "successRate": 100.0,
      "duration": 1.23
    }
  ]
}
```

---

## 🎯 測試策略

### 1. 單元測試層級

測試單一 AI 功能的基本行為：

```swift
func testFormatCitation() async throws {
    // Given
    let input = generateTestBibTeX()
    
    // When
    let result = try await aiService.formatCitation(input, style: "apa")
    
    // Then
    XCTAssertNotNil(result)
    XCTAssertTrue(result.contains("2024"))
}
```

### 2. 整合測試層級

測試多個功能組合：

```swift
func testCompleteWorkflow() async throws {
    // 1. 解析 BibTeX
    let entries = try await parseService.parse(bibtexContent)
    
    // 2. 格式化引用
    let citations = try await citationService.format(entries)
    
    // 3. 生成參考文獻
    let bibliography = try await bibliographyService.generate(entries)
    
    // 驗證完整流程
    XCTAssertGreaterThan(entries.count, 0)
    XCTAssertEqual(citations.count, entries.count)
    XCTAssertFalse(bibliography.isEmpty)
}
```

### 3. 端到端測試

測試完整的使用者場景：

```swift
func testUserScenario_CreatePaperWithCitations() async throws {
    // 1. 使用者創建文件
    let document = createDocument()
    
    // 2. 匯入文獻庫
    try await importLibrary("test.bib")
    
    // 3. 插入引用
    try await insertCitation(key: "smith2024")
    
    // 4. 生成參考文獻
    let bibliography = try await generateBibliography()
    
    // 5. 匯出 PDF
    let pdf = try await exportPDF()
    
    // 驗證最終輸出
    XCTAssertNotNil(pdf)
}
```

---

## 🐛 常見問題

### Q1: 如何測試真實的 AI 服務？

```swift
var config = AITestConfiguration()
config.useRealAIService = true  // 啟用真實 AI

// 注意：需要有可用的 AI 服務
```

### Q2: 如何跳過某些測試？

```swift
func testSomeFeature() async throws {
    throw XCTSkip("此功能尚未實現")
}
```

### Q3: 如何調試失敗的測試？

```swift
// 啟用詳細日誌
config.verboseLogging = true

// 在測試中加入 print
print("🔍 Debug: input = \(input)")
print("🔍 Debug: response = \(response)")
```

### Q4: 如何測試異步操作的超時？

```swift
func testTimeout() async throws {
    let result = try await AITestAssertions.assertExecutionTime({
        try await someAsyncOperation()
    }, maxDuration: 5.0)
}
```

---

## 📈 最佳實踐

### 1. 測試命名

```swift
// ✅ 好的命名
func testFormatCitation_WithAPAStyle_ReturnsCorrectFormat()
func testGenerateBibliography_WithMultipleEntries_SuccessfullyGenerates()

// ❌ 不好的命名
func test1()
func testStuff()
```

### 2. 測試組織

```swift
// MARK: - 測試組 1: 基本功能
func testBasicFeature1() { }
func testBasicFeature2() { }

// MARK: - 測試組 2: 邊界條件
func testEdgeCase1() { }
func testEdgeCase2() { }

// MARK: - 測試組 3: 錯誤處理
func testErrorHandling1() { }
func testErrorHandling2() { }
```

### 3. 測試資料管理

```swift
// 使用 setUp 準備共用測試資料
override func setUp() async throws {
    try await super.setUp()
    testData = prepareTestData()
}

// 使用 tearDown 清理
override func tearDown() async throws {
    testData = nil
    try await super.tearDown()
}
```

### 4. 斷言選擇

```swift
// ✅ 明確的斷言
XCTAssertEqual(result.count, 5, "應該返回 5 個結果")

// ❌ 模糊的斷言
XCTAssertTrue(result.count > 0)
```

---

## 🔧 維護指南

### 添加新的測試領域

1. 創建新的測試類實現 `AIDomainTestable`
2. 在 setUp 中配置 Mock 回應
3. 實現 `testAllFeatures()` 方法
4. 添加具體的測試用例方法
5. 更新整合測試以包含新領域

### 更新 Mock 回應

當 AI 服務的回應格式變更時：

```swift
// 在 setUp() 中更新
mockAI.mockResponses["tool_name"] = """
{
    "new_field": "value",
    "updated_format": true
}
"""
```

### 生成測試報告

```bash
# 執行測試並生成報告
xcodebuild test -project OVEREND.xcodeproj \
  -scheme OVEREND \
  -only-testing:OVERENDTests/AI

# 報告會自動生成在配置的路徑
cat ./TestReports/AITestReport.md
```

---

## 📚 相關資源

- [XCTest 官方文檔](https://developer.apple.com/documentation/xctest)
- [Swift Testing Best Practices](https://swift.org/documentation/)
- OVEREND 內部文檔：
  - `SKILL.md` - 專案開發指南
  - `README.md` - 專案概覽

---

**版本:** 1.0.0  
**最後更新:** 2026-01-19  
**維護者:** OVEREND Development Team
