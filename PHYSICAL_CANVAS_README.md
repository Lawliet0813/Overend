# OverEnd 物理畫布引擎 - 完整使用指南

## 📖 概述

OverEnd 物理畫布引擎是一個專為學術論文設計的 macOS 原生編輯器，提供嚴格遵守物理尺寸的 A4 頁面編輯體驗，確保螢幕顯示與 PDF 輸出完全一致。

## 🎯 核心特性

### 階段一：物理 A4 畫布引擎

#### 1. 物理尺寸精確控制
- **嚴格的 A4 規格**：210mm × 297mm
- **單位轉換系統**：`UnitLength` 支援毫米、公分、英寸、Points 互轉
- **螢幕 DPI 自適應**：自動偵測螢幕解析度，確保顯示尺寸正確

```swift
// 使用範例
let pageWidth = A4PageSize.width  // 210mm
let widthInPoints = pageWidth.toPoints  // 595.276 points
```

#### 2. 頁面模型 (PageModel)
- **邊距設定**：支援政大論文規範、Word 預設等預設模板
  - 上/下邊距：2.5cm
  - 左邊距：3cm
  - 右邊距：2cm
- **頁碼格式**：阿拉伯數字、羅馬數字、字母等多種格式
- **行政狀態**：封面、前言、正文、附錄等章節管理

#### 3. 視覺化輔助
- **標尺 (Rulers)**：顯示公分刻度，輔助排版
- **邊距導引線**：藍色虛線標示頁面邊界
- **物理座標網格**：除錯模式下顯示 1cm 網格

### 階段二：自動溢流與格式繼承

#### 1. 文字自動流動
```swift
// 當文字超過頁面高度時，系統自動：
// 1. 偵測溢出點
// 2. 創建新頁面
// 3. 將剩餘文字流向新頁
// 4. 繼承前一頁的所有樣式設定
```

#### 2. 孤行保護 (Orphan Protection)
- **避頭規則**：防止段落最後一行單獨出現在新頁開頭
- **避尾規則**：防止標題單獨留在頁面底部
- **智慧分段**：保持至少兩行在同一頁

#### 3. 格式繼承
新頁面自動繼承：
- 邊距設定
- 頁首/頁尾
- 頁碼格式
- 行政狀態
- 標尺與導引線顯示設定

### 階段三：元數據管理中心

#### 1. 論文元數據模型 (ThesisMetadata)
完整的論文資訊管理：

```swift
let metadata = ThesisMetadata(
    titleChinese: "智慧型文獻管理系統之設計與實作",
    titleEnglish: "Design and Implementation of...",
    authorChinese: "王小明",
    advisorChinese: "李教授",
    departmentChinese: "資訊科學系",
    degreeType: .master
)
```

#### 2. 動態標籤系統
在編輯器中使用 `{{TAG}}` 語法插入動態內容：

**基本標籤**
- `{{TITLE_CH}}` - 中文論文題目
- `{{AUTHOR_CH}}` - 中文作者姓名
- `{{ADVISOR_CH}}` - 指導教授
- `{{STUDENT_ID}}` - 學號

**日期標籤**
- `{{DATE_CH}}` - 中華民國 113 年 6 月
- `{{DATE_EN}}` - June, 2024
- `{{YEAR_ROC}}` - 113
- `{{YEAR_AD}}` - 2024

**學術資訊**
- `{{UNIVERSITY_CH}}` - 國立政治大學
- `{{DEPARTMENT_CH}}` - 資訊科學系
- `{{DEGREE_CH}}` - 碩士學位論文

#### 3. 全域聯動更新
當您在「論文資料卡」修改任何資訊時：
- 所有頁面的動態標籤**毫秒級同步更新**
- 封面、摘要、頁首等位置自動反映變更
- 無需手動查找替換

#### 4. 一鍵生成結構
點擊「生成論文結構」後自動建立：
- 封面頁（含完整元數據）
- 謝辭頁
- 中文摘要
- 英文摘要
- 目錄架構

### 階段四：AI 自訂指令控制台

#### 1. 快捷鍵啟動
按下 `Cmd + K` 彈出 AI 指令面板

#### 2. 預設指令範本

**語法與文體**
- 第三人稱視角檢查
- 學術用語檢查
- 語法錯誤檢查
- 改寫為被動語態
- 精簡冗長句子

**引用與格式**
- 文獻格式轉 APA
- 行政規範縮排
- 增加段落縮排

#### 3. 自訂指令
輸入任意自然語言指令，例如：
```
幫我把這段改成更正式的學術用語
```

```
檢查這段是否符合雙倍行距規範
```

#### 4. 上下文感知
AI 自動獲取：
- 選取的文字內容
- 當前字體與大小
- 段落樣式（行距、縮排等）
- 論文元數據

#### 5. 格式控制指令
AI 可直接修改格式，例如：
```json
{
  "action": "format",
  "changes": {
    "firstLineIndent": 28.35,
    "lineSpacing": 2.0,
    "paragraphSpacing": 0
  }
}
```

### 階段五：像素級 PDF 導出

#### 1. 同源渲染
- 使用 `PDFKit` 與 `Core Graphics` 原生渲染
- 座標系統與畫布 **1:1 對應**
- 不經過系統列印對話框，直接生成 PDF

#### 2. 字體嵌入
```swift
// 確保字體完全嵌入，避免跑版
PhysicalPDFExporter.embedFonts(in: pdfDocument)
```

支援字體：
- Times New Roman（學術標準）
- 新細明體（中文正文）
- 標楷體（封面標題）
- 自訂字體

#### 3. 元數據寫入
PDF 文件屬性包含：
- 標題（中英文）
- 作者
- 指導教授
- 學校系所
- 創建/修改日期
- 關鍵字

#### 4. 批次導出
```swift
PhysicalPDFExporter.batchExport(
    documents: [
        (pages: chapter1Pages, metadata: metadata, filename: "第一章"),
        (pages: chapter2Pages, metadata: metadata, filename: "第二章")
    ],
    to: outputDirectory,
    progressHandler: { current, total in
        print("進度：\(current)/\(total)")
    }
)
```

## 🚀 快速開始

### 基本工作流程

1. **新增文檔**
   ```swift
   let documentVM = PhysicalDocumentViewModel()
   ```

2. **設定元數據**
   - 點擊「編輯元數據」
   - 填寫論文基本資訊
   - 系統自動同步到所有動態標籤

3. **編輯內容**
   - 在物理畫布上直接輸入
   - 使用 `{{TAG}}` 插入動態內容
   - 文字溢出時自動建立新頁

4. **格式化**
   - 使用格式工具列調整字體、行距
   - 或按 `Cmd + K` 使用 AI 指令

5. **導出 PDF**
   - 點擊「導出 PDF」
   - 選擇儲存位置
   - 完成！

### 進階用法

#### 自訂頁面邊距
```swift
let customMargins = PageMargins(
    top: .centimeter(3.0),
    bottom: .centimeter(2.0),
    left: .centimeter(2.5),
    right: .centimeter(2.5)
)
page.margins = customMargins
```

#### 插入分頁符
```swift
documentViewModel.insertPageBreak()
```

#### 切換章節狀態
```swift
// 開始前言區（使用小寫羅馬數字頁碼）
documentViewModel.startNewSection(state: .preface, resetPageNumber: true)

// 開始正文（使用阿拉伯數字頁碼）
documentViewModel.startNewSection(state: .mainBody, resetPageNumber: true)
```

#### 動態標籤處理
```swift
// 在 NSTextView 中插入動態標籤
DynamicTagProcessor.insertTag("TITLE_CH", into: textView, metadata: metadata)

// 檢查是否包含動態標籤
if attributedString.containsDynamicTags {
    let processedString = attributedString.processingTags(with: metadata)
}
```

## 📐 技術架構

### 座標系統

```
物理座標（毫米）→ UnitLength → Points → 螢幕顯示 → PDF 輸出
     ↓              ↓            ↓          ↓           ↓
   210mm         8.27in      595.276pt   縮放顯示    1:1對應
```

### 資料流程

```
用戶輸入 → NSTextView → NSTextStorage → PageModel.contentData
                                              ↓
                                    DynamicTagProcessor
                                              ↓
                                    PhysicalPDFExporter
                                              ↓
                                          PDF 檔案
```

### 模組關係

```
PhysicalEditorMainView
    ├── PhysicalDocumentViewModel (頁面管理)
    │   └── PageModel[] (頁面陣列)
    ├── ThesisMetadata (元數據)
    │   └── DynamicTagProcessor (標籤處理)
    ├── AICommandExecutor (AI 指令)
    │   └── Gemini API
    └── PhysicalPDFExporter (PDF 導出)
```

## 🔧 設定需求

### Gemini API Key

要使用 AI 功能，需要設定環境變數：

```bash
export GEMINI_API_KEY="your-api-key-here"
```

或在程式中直接設定：

```swift
let aiExecutor = AICommandExecutor(apiKey: "your-api-key")
```

### 系統需求

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## 📊 效能優化

### 大型文檔處理
- 使用惰性載入（LazyVStack）處理頁面列表
- NSTextView 重用機制
- 背景執行溢流計算

### 記憶體管理
- 頁面內容使用 RTF Data 儲存（節省記憶體）
- 弱引用避免循環引用
- 及時釋放未使用的 PDF 上下文

## 🐛 除錯工具

### 顯示物理網格
```swift
// 在 UserDefaults 設定
UserDefaults.standard.set(true, forKey: "ShowPhysicalGrid")
```

### 列印座標資訊
```swift
if let physicalPosition = textView.currentPhysicalPosition() {
    print("游標物理座標：\(physicalPosition)")
}

let remaining = textView.remainingHeight()
print("剩餘可用高度：\(remaining)pt")
```

## 📚 範例專案

完整範例請參考：
- `PhysicalEditorMainView.swift` - 主要整合範例
- `MultiPageDocumentView.swift` - 多頁面編輯
- `ThesisMetadataEditorView.swift` - 元數據編輯

## 🤝 貢獻指南

歡迎提交 Issue 或 Pull Request！

主要開發領域：
1. 新增更多論文格式範本（APA、MLA、Chicago）
2. 擴展 AI 指令範本
3. 支援更多語言（英文、日文）
4. 改進溢流演算法

## 📄 授權

MIT License

## 🙏 致謝

感謝以下技術與專案的啟發：
- Apple TextKit Framework
- PDFKit
- Google Gemini API
- SwiftUI & SwiftData

---

**OverEnd 團隊** © 2024

如有問題，請聯繫：support@overend.app
