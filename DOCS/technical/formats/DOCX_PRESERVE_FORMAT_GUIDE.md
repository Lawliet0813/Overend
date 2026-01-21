# DOCX 格式保留功能使用說明

## 功能概述

OVEREND 現在支援**完整保留 DOCX 原始格式**的匯入功能，讓你匯入的 Word 檔案可以無縫繼續編輯，不需要重新調整排版。

## 新增的方法

### 1. `importPreservingFormat` - 完整保留格式

```swift
let attributedString = try WordImporter.importPreservingFormat(from: docxURL)
// 直接回傳 NSAttributedString，完整保留原始格式
```

**特點：**
- ✅ 保留所有字體、字型大小、顏色
- ✅ 保留段落對齊、行距、縮排
- ✅ 保留粗體、斜體、底線等樣式
- ❌ 不套用 OVEREND 範本

### 2. `importWithOption` - 彈性選擇

```swift
// 選項 A：保留原始格式
let preservedString = try WordImporter.importWithOption(
    from: docxURL,
    preserveFormatting: true
)

// 選項 B：套用 OVEREND 學術範本
let styledString = try WordImporter.importWithOption(
    from: docxURL,
    preserveFormatting: false,
    template: myTemplate
)
```

## 使用場景對比

| 功能 | 原始 `import()` | 新增 `importPreservingFormat()` |
|------|----------------|--------------------------------|
| 保留字體 | ❌ 轉換成標題/正文 | ✅ 完整保留 |
| 保留顏色 | ❌ 移除 | ✅ 完整保留 |
| 保留表格 | ⚠️ 基本格式 | ✅ 完整保留 |
| 套用範本 | ✅ 統一學術格式 | ❌ 不處理 |
| 適用場景 | 建立新文稿 | 編輯現有文件 |

## 實際使用範例

### 在 DocumentViewModel 中使用

```swift
func importWord(from url: URL, preserveFormat: Bool) {
    do {
        let content: NSAttributedString
        
        if preserveFormat {
            // 完整保留原始格式
            content = try WordImporter.importPreservingFormat(from: url)
        } else {
            // 套用 OVEREND 範本
            let template = FormatTemplate.default
            content = try WordImporter.import(from: url, template: template)
        }
        
        // 儲存到 Document
        document.attributedString = content
        
    } catch {
        print("匯入失敗：\(error)")
    }
}
```

### 在 UI 中提供選項

```swift
Button("匯入 Word 文件") {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.init(filenameExtension: "docx")!]
    
    if panel.runModal() == .OK, let url = panel.url {
        // 彈出選項對話框
        let alert = NSAlert()
        alert.messageText = "匯入選項"
        alert.informativeText = "選擇如何處理格式："
        alert.addButton(withTitle: "保留原始格式")
        alert.addButton(withTitle: "套用 OVEREND 範本")
        
        let response = alert.runModal()
        let preserveFormat = (response == .alertFirstButtonReturn)
        
        viewModel.importWord(from: url, preserveFormat: preserveFormat)
    }
}
```

## 技術細節

### macOS 格式轉換

使用 macOS 內建的 Office Open XML 轉換器：

```swift
let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
    .documentType: NSAttributedString.DocumentType.officeOpenXML
]

let attributedString = try NSAttributedString(
    data: data,
    options: options,
    documentAttributes: nil
)
```

### 格式保留範圍

✅ **完整保留：**
- 文字內容
- 字體（名稱、大小、粗細、斜體）
- 顏色（文字顏色、背景色）
- 段落格式（對齊、縮排、行距）
- 基本表格

⚠️ **部分保留：**
- 圖片（取決於 macOS 轉換器）
- 超連結（保留但可能需要處理）

❌ **不保留：**
- 頁首/頁尾
- 頁碼
- 註解/追蹤修訂
- 巨集

### 儲存格式

OVEREND 使用 **RTF（Rich Text Format）** 儲存：

```swift
// Document.swift
var attributedString: NSAttributedString {
    get {
        // 從 RTF Data 讀取
        try NSAttributedString(
            data: rtfData,
            options: [.documentType: .rtf],
            documentAttributes: nil
        )
    }
    set {
        // 轉換成 RTF Data
        let data = try newValue.data(
            from: NSRange(location: 0, length: newValue.length),
            documentAttributes: [.documentType: .rtf]
        )
        rtfData = data
    }
}
```

**RTF 支援的格式：**
- 字體樣式（粗體、斜體、顏色）
- 段落格式（對齊、縮排）
- 表格（基本）
- 圖片（內嵌）

## 注意事項

1. **僅支援 .docx**
   - macOS 原生支援 Office Open XML (.docx)
   - 不支援舊版 .doc 格式

2. **格式轉換限制**
   - macOS 轉換器可能無法 100% 還原複雜格式
   - 建議測試實際使用的文件

3. **儲存格式差異**
   - DOCX → NSAttributedString → RTF → Core Data
   - 每次轉換可能有些微差異

## 建議使用方式

### 情境 A：從頭撰寫新文稿
→ 使用原本的 `import()` + 範本系統
→ 統一學術格式，符合論文規範

### 情境 B：編輯現有 Word 文件
→ 使用新的 `importPreservingFormat()`
→ 保留原始排版，直接繼續編輯

### 情境 C：不確定
→ 使用 `importWithOption()` 讓使用者選擇
→ 提供彈性，兼顧兩種需求
