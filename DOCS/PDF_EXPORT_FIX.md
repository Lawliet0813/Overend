# PDF 匯出錯誤修復報告

## 問題描述

**症狀**：匯出的 PDF 顯示亂碼內容（PK、FK、driver、license 等片段），而非實際文檔內容。

**日期**：2026-01-01

## 根本原因分析

### 雙重轉換問題

OVEREND 的 Document 模型同時儲存兩種格式：
1. **RTF 格式**（`rtfData`）- 向下相容
2. **HTML 格式**（`htmlData`）- 新增功能

**問題流程**：

```
1. 用戶編輯文檔 → 儲存時：
   NSAttributedString → HTML (第一次轉換) → 儲存到 htmlData

2. 匯出 PDF 時：
   htmlData → NSAttributedString (第二次轉換) → HTML (第三次轉換) → PDF
```

**結果**：多次轉換導致內容損壞，特別是：
- 屬性丟失
- 格式錯亂
- 可能讀取到錯誤的資料片段（metadata、file headers 等）

## 修復方案

### 核心修正：避免雙重轉換

修改 `Document.exportToPDF()` 方法，直接使用已儲存的 HTML：

```swift
// BEFORE (錯誤的方式)
func exportToPDF(to url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
    // 這會觸發：htmlData → NSAttributedString → HTML (雙重轉換)
    PDFExporter.export(document: self, template: template, to: url, completion: completion)
}

// AFTER (正確的方式)
func exportToPDF(to url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
    if let htmlData = htmlData,
       let existingHTML = String(data: htmlData, encoding: .utf8) {
        // 直接使用已儲存的 HTML，避免雙重轉換
        PDFExporter.exportFromHTML(existingHTML, template: template, to: url, completion: completion)
    } else {
        // 回退到舊方式（RTF 資料）
        PDFExporter.export(document: self, template: template, to: url, completion: completion)
    }
}
```

### 新增功能

**PDFExporter.exportFromHTML()**

新增直接使用 HTML 匯出的方法：

```swift
static func exportFromHTML(
    _ html: String,
    template: FormatTemplate,
    to url: URL,
    completion: @escaping (Result<Void, Error>) -> Void
)
```

**優點**：
- 避免不必要的格式轉換
- 保持資料完整性
- 提升效能（減少轉換開銷）

## 除錯功能增強

### 1. Document.attributedString Getter/Setter 日誌

```swift
📖 Document.attributedString getter 被呼叫
  └─ 使用 HTML 資料（長度：12345 bytes）
  └─ HTML 前 200 字元：<!DOCTYPE html>...
  └─ 轉換後的 NSAttributedString 長度：5678
  └─ 轉換後的純文字前 200 字元：...

💾 Document.attributedString setter 被呼叫
  └─ 新值長度：5678
  └─ 新值純文字前 200 字元：...
  └─ 生成的 HTML 長度：12345
  └─ RTF 資料大小：9876 bytes
```

### 2. DocumentFormatter.parseAttributedString() 日誌

```swift
🔍 parseAttributedString - 原始長度：5678
🔍 parseAttributedString - 純文字長度：5678
🔍 parseAttributedString - 前 200 字元：...
🔍 parseAttributedString - 段落數：123
🔍 處理段落 0/123 - 長度：45
⚠️ 段落 5 包含附件，使用純文字輸出
🔍 parseAttributedString - 完成！HTML 長度：12345
```

### 3. PDFExporter 日誌

```swift
📄 PDF Export (from HTML) - HTML 長度：12345 字元
📄 PDF Export (from HTML) - 內容預覽：<!DOCTYPE html>...
✅ WebView HTML 載入完成
📏 WebView 內容長度：12000 字元
📏 WebView 內容高度：2480 px
✅ PDF 建立成功，大小：456789 bytes
✅ PDF 已儲存至：/path/to/file.pdf
```

### 4. NSTextAttachment 處理

新增檢測 NSTextAttachment（LaTeX 公式圖片等）：

```swift
// 檢查段落是否包含附件
if hasAttachment {
    print("⚠️ 段落包含附件，使用純文字輸出")
    html += "<p>\(escapeHTML(paragraph))</p>\n"
    continue
}
```

## 測試步驟

### 1. 測試現有文檔

1. 打開一個已有內容的文檔
2. 匯出為 PDF
3. 觀察 Console 輸出：
   - 應該看到 `✅ 使用已儲存的 HTML 直接匯出 PDF`
   - HTML 前 200 字元應該顯示正確的文檔開頭

### 2. 測試新建文檔

1. 建立新文檔，輸入內容
2. 儲存
3. 匯出為 PDF
4. 觀察 Console 輸出：
   - 第一次可能使用 RTF 轉換
   - 之後應該使用 HTML 直接匯出

### 3. 驗證 PDF 內容

1. 打開匯出的 PDF
2. 確認：
   - ✅ 內容正確顯示
   - ✅ 格式保持一致
   - ✅ 分頁正常
   - ✅ 無亂碼

## 已修改的檔案

1. **OVEREND/Models/Document.swift**
   - `attributedString` getter：新增除錯日誌
   - `attributedString` setter：新增除錯日誌
   - `exportToPDF()`：改用直接 HTML 匯出

2. **OVEREND/Services/PDFExporter.swift**
   - 新增 `exportFromHTML()` 方法
   - 重構 `loadHTMLAndExport()` 共用方法

3. **OVEREND/Services/DocumentFormatter.swift**
   - `parseAttributedString()`：新增除錯日誌
   - 新增 NSTextAttachment 檢測
   - 新增空內容檢查

## 預期結果

- ✅ PDF 匯出顯示正確的文檔內容
- ✅ 無亂碼（PK、FK、driver 等）
- ✅ 格式保持完整
- ✅ Console 輸出詳細除錯資訊

## 已知問題與後續改進

### 目前狀態

- ✅ 修復雙重轉換問題
- ✅ 新增詳細除錯日誌
- ✅ 新增 NSTextAttachment 處理
- ⚠️ 尚未實際測試（需要用戶運行應用程式）

### 後續可能需要的改進

1. **LaTeX 公式 PDF 匯出**
   - 目前 NSTextAttachment 會被跳過
   - 未來需要將 LaTeX 公式圖片正確嵌入 HTML

2. **HTML 生成優化**
   - 考慮使用更穩定的 HTML 生成方式
   - 避免手動字串拼接

3. **移除除錯日誌**
   - 在確認修復後，可以將部分 print 語句改為條件編譯
   - 只在 DEBUG 模式下輸出

## 編譯狀態

✅ **BUILD SUCCEEDED** - 所有修改已成功編譯

## 下一步行動

1. **運行應用程式並測試**
   - 打開 OVEREND
   - 建立或打開文檔
   - 匯出 PDF
   - 檢查 Console 輸出
   - 驗證 PDF 內容

2. **回報測試結果**
   - 如果仍有問題，提供 Console 完整輸出
   - 截圖顯示 PDF 內容
   - 描述任何異常行為

---

**修復日期**：2026-01-01
**狀態**：✅ 已完成修改，等待測試
