# OverEnd 物理畫布引擎 - 系統架構文件

## 🏗️ 系統架構總覽

```
┌─────────────────────────────────────────────────────────────────┐
│                    PhysicalEditorMainView                       │
│                      (主要整合視圖)                              │
└─────────────────────────────────────────────────────────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
    ┌────────────────────────┐      ┌──────────────────────────┐
    │ PhysicalDocumentVM      │      │  ThesisMetadata         │
    │ (文檔管理)              │      │  (元數據管理)            │
    │                        │      │                          │
    │ • pages: [PageModel]   │      │ • titleChinese          │
    │ • currentPageIndex     │      │ • authorChinese         │
    │ • autoFlowEnabled      │      │ • advisorChinese        │
    │ • totalWordCount()     │◄─────┤ • resolveTag()          │
    └────────────────────────┘      └──────────────────────────┘
                 │                               │
                 ▼                               ▼
    ┌────────────────────────┐      ┌──────────────────────────┐
    │ PageModel              │      │ DynamicTagProcessor      │
    │                        │      │                          │
    │ • pageNumber           │      │ • process()             │
    │ • margins              │      │ • insertTag()           │
    │ • contentData          │      │ • setupLiveUpdate()     │
    │ • createNextPage()     │      └──────────────────────────┘
    └────────────────────────┘
                 │
                 ▼
    ┌─────────────────────────────────────────────────────────────┐
    │                   PhysicalCanvasView                         │
    │                   (核心畫布視圖)                             │
    │                                                              │
    │  ┌────────────┐  ┌─────────────┐  ┌──────────────────────┐ │
    │  │  Rulers    │  │  Margin     │  │ PhysicalTextEditor   │ │
    │  │ (標尺)     │  │  Guides     │  │ (NSTextView 封裝)    │ │
    │  └────────────┘  └─────────────┘  └──────────────────────┘ │
    └─────────────────────────────────────────────────────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
    ┌────────────────────────┐      ┌──────────────────────────┐
    │ AICommandExecutor      │      │ PhysicalPDFExporter      │
    │                        │      │                          │
    │ • execute()            │      │ • export()              │
    │ • callGeminiAPI()      │      │ • renderPage()          │
    │ • applyResult()        │      │ • embedMetadata()       │
    └────────────────────────┘      └──────────────────────────┘
                 │                               │
                 ▼                               ▼
         Gemini API                      PDF Document
```

## 📦 檔案結構

```
OVEREND/
├── Models/
│   ├── PhysicalCanvas/
│   │   └── PageModel.swift                 [階段一] 頁面模型
│   ├── ThesisMetadata.swift                [階段三] 論文元數據
│   ├── Document.swift                       現有文檔模型
│   └── ...
│
├── ViewModels/
│   └── PhysicalDocumentViewModel.swift     [階段二] 文檔視圖模型
│
├── Views/
│   ├── PhysicalCanvas/
│   │   ├── PhysicalCanvasView.swift        [階段一] 主畫布視圖
│   │   ├── PhysicalTextEditorView.swift    [階段一] 文字編輯器
│   │   ├── RulerViews.swift                [階段一] 標尺組件
│   │   ├── MultiPageDocumentView.swift     [階段二] 多頁面視圖
│   │   └── PhysicalEditorMainView.swift    [整合] 主視圖
│   │
│   ├── Metadata/
│   │   └── ThesisMetadataEditorView.swift  [階段三] 元數據編輯器
│   │
│   ├── AICommand/
│   │   └── AICommandPaletteView.swift      [階段四] AI 指令面板
│   │
│   └── ...
│
├── Services/
│   ├── DynamicTagProcessor.swift           [階段三] 動態標籤處理
│   ├── AICommandExecutor.swift             [階段四] AI 指令執行
│   ├── PhysicalPDFExporter.swift           [階段五] PDF 導出引擎
│   └── ...
│
└── Documentation/
    ├── PHYSICAL_CANVAS_README.md           完整使用指南
    ├── PHYSICAL_CANVAS_QUICK_START.md      快速開始
    └── PHYSICAL_CANVAS_ARCHITECTURE.md     本文件
```

## 🔄 資料流程圖

### 編輯流程

```
用戶輸入文字
    │
    ▼
NSTextView (LaTeXSupportedTextView)
    │
    ▼
NSTextStorage
    │
    ├─► DynamicTagProcessor.process() ─► 解析 {{TAG}}
    │                                      │
    │                                      ▼
    │                              ThesisMetadata.resolveTag()
    │                                      │
    │                                      ▼
    │                              返回解析後的值
    │
    ▼
檢查文字溢流
    │
    ├─► 未溢流 ─► 儲存到 PageModel.contentData
    │
    └─► 溢流 ─► PhysicalDocumentViewModel
                      │
                      ▼
                 adjustOverflowPosition() [孤行保護]
                      │
                      ▼
                 splitText() [分割文字]
                      │
                      ▼
                 createNextPage() [建立新頁，繼承格式]
                      │
                      ▼
                 將剩餘文字流向新頁
```

### AI 指令流程

```
用戶按下 Cmd+K
    │
    ▼
AICommandPaletteView 顯示
    │
    ├─► 選擇預設範本
    │   │
    │   └─► CommandTemplate.prompt
    │
    └─► 輸入自訂指令
    │
    ▼
AICommand 建構
    │
    ├─► 獲取選取文字
    ├─► 獲取當前格式屬性
    └─► 獲取論文元數據
    │
    ▼
AICommandExecutor.execute()
    │
    ├─► buildPrompt() ─► 組合完整提示詞
    │
    ├─► callGeminiAPI() ─► 呼叫 Gemini
    │
    ├─► parseResponse() ─► 解析回應
    │       │
    │       ├─► JSON 格式 ─► 格式修改指令
    │       └─► 純文字 ─► 文字替換
    │
    └─► applyResult() ─► 套用到 NSTextView
            │
            ├─► textReplacement ─► 替換文字
            └─► formatChange ─► 修改段落樣式
```

### PDF 導出流程

```
用戶點擊「導出 PDF」
    │
    ▼
PhysicalPDFExporter.export()
    │
    └─► for each page in pages:
            │
            ▼
        renderPage()
            │
            ├─► 創建 PDF 上下文
            ├─► 設定 A4 尺寸 (595.276 × 841.890 pts)
            ├─► 翻轉座標系（PDF 原點在左下）
            │
            ├─► drawMarginGuides() [除錯用]
            │
            ├─► drawHeader()
            │   └─► 在上邊距繪製頁首
            │
            ├─► drawContent()
            │   ├─► 載入 PageModel.contentData
            │   ├─► 解析 RTF 為 NSAttributedString
            │   ├─► DynamicTagProcessor.process()
            │   ├─► 創建 CTFramesetter
            │   └─► CTFrameDraw() ─► 精確排版
            │
            └─► drawFooter()
                └─► 繪製頁碼與頁尾
    │
    ▼
embedMetadata()
    │
    ├─► 寫入標題、作者
    ├─► 寫入學校、系所
    └─► 寫入關鍵字、日期
    │
    ▼
pdfDocument.write(to: url)
    │
    ▼
完成！
```

## 🎯 核心類別詳解

### 1. PageModel

**職責**：代表一個物理 A4 頁面

```swift
class PageModel {
    // 識別與編號
    let id: UUID
    var pageNumber: Int
    var pageNumberStyle: PageNumberStyle  // arabic, romanLower, etc.

    // 行政狀態
    var administrativeState: AdministrativeState  // cover, preface, mainBody

    // 物理屬性
    var margins: PageMargins  // 上下左右邊距
    var contentSize: CGSize   // 扣除邊距後的內容區域
    var contentOrigin: CGPoint // 內容起始座標

    // 內容
    var contentData: Data?     // RTF 格式
    var headerText: String?
    var footerText: String?

    // 方法
    func createNextPage() -> PageModel  // 繼承樣式建立新頁
    func inheritStyle(from: PageModel)   // 繼承另一頁的樣式
}
```

### 2. PhysicalDocumentViewModel

**職責**：管理多頁面文檔與自動溢流

```swift
class PhysicalDocumentViewModel: ObservableObject {
    @Published var pages: [PageModel]
    @Published var currentPageIndex: Int

    // 頁面管理
    func addPage(after: Int?) -> PageModel
    func deletePage(at: Int)
    func insertPageBreak()

    // 溢流處理
    func checkAndHandleOverflow(...)
    private func performAutoFlow(...)
    private func adjustOverflowPosition(...)  // 孤行保護

    // 狀態管理
    func startNewSection(state: AdministrativeState, resetPageNumber: Bool)

    // 統計
    func totalWordCount() -> Int
    func totalCharacterCount() -> Int
}
```

### 3. DynamicTagProcessor

**職責**：處理動態標籤解析與替換

```swift
class DynamicTagProcessor {
    // 解析並替換
    static func process(
        attributedString: NSAttributedString,
        metadata: ThesisMetadata
    ) -> NSAttributedString

    // 檢測標籤
    static func containsTags(in text: String) -> Bool
    static func extractTags(from text: String) -> [String]

    // 實時更新
    static func setupLiveUpdate(
        for textView: NSTextView,
        metadata: ThesisMetadata,
        updateInterval: TimeInterval
    ) -> Timer

    // 插入標籤
    static func insertTag(
        _ tagName: String,
        into textView: NSTextView,
        metadata: ThesisMetadata
    )
}
```

### 4. PhysicalPDFExporter

**職責**：像素級精確 PDF 導出

```swift
class PhysicalPDFExporter {
    // 主要導出
    static func export(
        pages: [PageModel],
        metadata: ThesisMetadata?,
        to url: URL
    ) throws

    // 頁面渲染
    private static func renderPage(
        _ page: PageModel,
        metadata: ThesisMetadata?
    ) throws -> PDFPage

    // 繪製組件
    private static func drawHeader(...)
    private static func drawContent(...)
    private static func drawFooter(...)

    // 元數據
    private static func embedMetadata(...)

    // 批次導出
    static func batchExport(...)
}
```

## 🔌 擴展點

### 1. 新增論文格式範本

```swift
// 在 PageMargins 擴展新增
extension PageMargins {
    static let apa = PageMargins(
        top: .inch(1.0),
        bottom: .inch(1.0),
        left: .inch(1.0),
        right: .inch(1.0)
    )
}
```

### 2. 新增動態標籤

```swift
// 在 ThesisMetadata.resolveTag() 中新增
case "CUSTOM_TAG":
    return customValue
```

### 3. 新增 AI 指令範本

```swift
CommandTemplate(
    icon: "custom.icon",
    title: "自訂指令",
    prompt: "您的提示詞",
    category: .custom
)
```

### 4. 自訂 PDF 渲染

```swift
// 繼承並覆寫
class CustomPDFExporter: PhysicalPDFExporter {
    override func renderPage(...) -> PDFPage {
        // 自訂渲染邏輯
    }
}
```

## ⚡ 效能考量

### 記憶體優化

1. **頁面內容惰性載入**
   - 只在需要時解析 RTF Data
   - 使用 LazyVStack 顯示頁面列表

2. **圖片處理**
   - 縮圖異步生成
   - 原始圖片延遲載入

3. **文字處理**
   - 使用 NSTextStorage 原生機制
   - 避免不必要的 AttributedString 轉換

### 渲染優化

1. **畫布縮放**
   - 根據視窗大小自動計算縮放比例
   - 避免過度繪製

2. **標尺繪製**
   - 使用 Canvas 而非 Shape
   - 只繪製可見範圍

3. **PDF 導出**
   - 直接使用 Core Graphics
   - 避免中間格式轉換

## 🧪 測試策略

### 單元測試

```swift
// 單位轉換測試
func testUnitConversion() {
    let mm = UnitLength.millimeter(210)
    XCTAssertEqual(mm.toPoints, 595.276, accuracy: 0.01)
}

// 頁碼格式測試
func testPageNumberFormatting() {
    XCTAssertEqual(PageNumberStyle.romanLower.format(3), "iii")
}

// 動態標籤測試
func testTagResolution() {
    let metadata = ThesisMetadata.preview
    XCTAssertEqual(metadata.resolveTag("TITLE_CH"), metadata.titleChinese)
}
```

### 整合測試

```swift
// 溢流測試
func testAutoFlow() {
    let vm = PhysicalDocumentViewModel()
    // 插入超長文字
    // 驗證自動建立新頁
    XCTAssertGreaterThan(vm.pages.count, 1)
}

// PDF 導出測試
func testPDFExport() {
    let pages = [PageModel.preview]
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "test.pdf")
    XCTAssertNoThrow(try PhysicalPDFExporter.export(pages: pages, to: tempURL))
}
```

## 🔒 安全性考量

1. **API Key 管理**
   - 不硬編碼在程式碼中
   - 使用環境變數或 Keychain

2. **檔案存取**
   - 使用 App Sandbox
   - 明確請求權限

3. **資料驗證**
   - 檢查 RTF Data 有效性
   - 防止注入攻擊

## 📈 未來發展方向

1. **多人協作**
   - 即時同步
   - 版本控制

2. **雲端整合**
   - iCloud 同步
   - Google Drive 支援

3. **更多 AI 功能**
   - 自動摘要生成
   - 文獻推薦
   - 查重檢測

4. **跨平台**
   - iOS 版本
   - Web 版本

---

**維護者**：OverEnd 開發團隊
**最後更新**：2024-01-02
